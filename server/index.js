/**
 * TalkTranslate 信令服务器
 *
 * WebSocket 协议:
 *
 * 客户端 → 服务器:
 *   { type: "register",  phone: "+8613800138000" }
 *   { type: "call",      to: "+8613800138001" }
 *   { type: "answer",    callId: "xxx", accepted: true }
 *   { type: "ice",       callId: "xxx", candidate: {...} }
 *   { type: "offer",     callId: "xxx", sdp: "..." }
 *   { type: "answer-sdp", callId: "xxx", sdp: "..." }
 *   { type: "end-call",  callId: "xxx" }
 *
 * 服务器 → 客户端:
 *   { type: "registered", phone: "+8613800138000" }
 *   { type: "incoming",   from: "+8613800138000", callId: "xxx" }
 *   { type: "ringing",    to: "+8613800138001", callId: "xxx" }
 *   { type: "accepted",   callId: "xxx" }
 *   { type: "rejected",   callId: "xxx" }
 *   { type: "offer",      callId: "xxx", sdp: "..." }
 *   { type: "answer-sdp", callId: "xxx", sdp: "..." }
 *   { type: "ice",        callId: "xxx", candidate: {...} }
 *   { type: "call-ended", callId: "xxx", reason: "..." }
 *   { type: "error",      message: "..." }
 */

import { WebSocketServer } from "ws";
import { v4 as uuid } from "uuid";

const PORT = process.env.PORT || 3459;

// ── 在线用户 ──
// phone → { ws, registeredAt }
const users = new Map();

// ── 通话 ──
// callId → { from, to, status }
const calls = new Map();

// ── WebSocket 服务器 ──
const wss = new WebSocketServer({ port: PORT });
console.log(`\n  📞 TalkTranslate 信令服务器`);
console.log(`  ⚡ ws://0.0.0.0:${PORT}\n`);

wss.on("connection", (ws) => {
  let phone = null;

  ws.on("message", (raw) => {
    let msg;
    try {
      msg = JSON.parse(raw.toString());
    } catch {
      return send(ws, { type: "error", message: "无效的JSON" });
    }

    switch (msg.type) {
      // ── 注册 ──
      case "register":
        phone = msg.phone;
        if (!phone) return send(ws, { type: "error", message: "缺少手机号" });

        // 踢掉旧连接
        const old = users.get(phone);
        if (old && old.ws !== ws) {
          send(old.ws, { type: "error", message: "另一设备登录" });
          old.ws.close();
        }

        users.set(phone, { ws, registeredAt: Date.now() });
        send(ws, { type: "registered", phone });
        console.log(`  ✅ 在线: ${phone} (${users.size} 人在线)`);
        broadcastOnline();
        break;

      // ── 拨号 ──
      case "call": {
        const to = msg.to;
        if (!to) return send(ws, { type: "error", message: "缺少对方手机号" });
        if (to === phone) return send(ws, { type: "error", message: "不能呼叫自己" });

        const target = users.get(to);
        if (!target) return send(ws, { type: "error", message: "对方不在线" });

        const callId = uuid();
        calls.set(callId, { from: phone, to, status: "ringing", fromWs: ws, toWs: target.ws });

        send(target.ws, { type: "incoming", from: phone, callId });
        send(ws, { type: "ringing", to, callId });
        console.log(`  🔔 呼叫: ${phone} → ${to} (${callId.slice(0, 8)})`);
        break;
      }

      // ── 接听/拒接 ──
      case "answer": {
        const call = calls.get(msg.callId);
        if (!call) return send(ws, { type: "error", message: "通话不存在" });

        if (msg.accepted) {
          call.status = "connected";
          send(call.fromWs, { type: "accepted", callId: msg.callId });
          console.log(`  ✅ 接听: ${call.from} ↔ ${call.to}`);
        } else {
          send(call.fromWs, { type: "rejected", callId: msg.callId });
          calls.delete(msg.callId);
          console.log(`  ❌ 拒接: ${call.from} → ${call.to}`);
        }
        break;
      }

      // ── WebRTC SDP ──
      case "offer": {
        const call = calls.get(msg.callId);
        if (!call) return;
        send(call.toWs, { type: "offer", callId: msg.callId, sdp: msg.sdp });
        break;
      }
      case "answer-sdp": {
        const call = calls.get(msg.callId);
        if (!call) return;
        send(call.fromWs, { type: "answer-sdp", callId: msg.callId, sdp: msg.sdp });
        break;
      }

      // ── ICE Candidate ──
      case "ice": {
        const call = calls.get(msg.callId);
        if (!call) return;
        const target = msg.to === call.from ? call.toWs : call.fromWs;
        send(target, { type: "ice", callId: msg.callId, candidate: msg.candidate, from: msg.to });
        break;
      }

      // ── 结束通话 ──
      case "end-call": {
        const call = calls.get(msg.callId);
        if (!call) return;
        send(call.fromWs, { type: "call-ended", callId: msg.callId, reason: "对方挂断" });
        send(call.toWs, { type: "call-ended", callId: msg.callId, reason: "对方挂断" });
        calls.delete(msg.callId);
        console.log(`  🔚 挂断: ${call.from} ↔ ${call.to}`);
        break;
      }

      default:
        send(ws, { type: "error", message: `未知消息类型: ${msg.type}` });
    }
  });

  ws.on("close", () => {
    if (phone) {
      users.delete(phone);
      // 结束该用户的所有通话
      for (const [id, call] of calls) {
        if (call.from === phone || call.to === phone) {
          const other = call.from === phone ? call.toWs : call.fromWs;
          send(other, { type: "call-ended", callId: id, reason: "对方离线" });
          calls.delete(id);
        }
      }
      console.log(`  ❌ 离线: ${phone} (${users.size} 人在线)`);
      broadcastOnline();
    }
  });
});

function send(ws, data) {
  try {
    ws.send(JSON.stringify(data));
  } catch {}
}

function broadcastOnline() {
  const online = [...users.keys()];
  for (const [, { ws }] of users) {
    send(ws, { type: "online-list", users: online });
  }
}
