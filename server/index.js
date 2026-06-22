/**
 * TalkTranslate v2 信令服务器
 *
 * WebSocket 协议:
 *   C→S: { type:"register",  phone:"+8613800138000" }
 *   C→S: { type:"call",      to:"+8613800138001" }
 *   C→S: { type:"accept",    callId:"xxx" }
 *   C→S: { type:"reject",    callId:"xxx" }
 *   C→S: { type:"offer",     callId:"xxx", sdp:"..." }
 *   C→S: { type:"answer",    callId:"xxx", sdp:"..." }
 *   C→S: { type:"ice",       callId:"xxx", candidate:{...} }
 *   C→S: { type:"hangup",    callId:"xxx" }
 *
 *   S→C: { type:"registered", phone:"..." }
 *   S→C: { type:"incoming",   from:"...", callId:"xxx" }
 *   S→C: { type:"ringing",    to:"...", callId:"xxx" }
 *   S→C: { type:"accepted",   callId:"xxx" }
 *   S→C: { type:"rejected",   callId:"xxx" }
 *   S→C: { type:"offer",      callId:"xxx", sdp:"...", from:"..." }
 *   S→C: { type:"answer",     callId:"xxx", sdp:"..." }
 *   S→C: { type:"ice",        callId:"xxx", candidate:{...}, from:"..." }
 *   S→C: { type:"hangup",     callId:"xxx", from:"..." }
 *   S→C: { type:"online",     users:["+86...", ...] }
 *   S→C: { type:"error",      message:"..." }
 */

import { WebSocketServer } from "ws";
import { v4 as uuid } from "uuid";

const PORT = process.env.PORT || 3459;
const wss = new WebSocketServer({ port: PORT });

// phone → { ws, registeredAt }
const users = new Map();
// callId → { from, to, status }
const calls = new Map();

console.log(`\n  📞 TalkTranslate v2 信令服务器`);
console.log(`  ⚡ ws://0.0.0.0:${PORT}\n`);

function send(ws, data) {
  try { ws.send(JSON.stringify(data)); } catch {}
}

function broadcastOnline() {
  const list = [...users.keys()];
  for (const [, { ws }] of users) send(ws, { type: "online", users: list });
}

wss.on("connection", (ws) => {
  let phone = null;

  ws.on("message", (raw) => {
    let msg;
    try { msg = JSON.parse(raw.toString()); } catch { return send(ws, { type: "error", message: "无效JSON" }); }

    switch (msg.type) {
      // ── 注册 ──
      case "register":
        phone = msg.phone;
        if (!phone) return send(ws, { type: "error", message: "缺少手机号" });
        users.set(phone, { ws, at: Date.now() });
        send(ws, { type: "registered", phone });
        console.log(`  ✅ 在线: ${phone} (${users.size}人)`);
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
        calls.set(callId, { from: phone, to, status: "ringing" });
        send(target.ws, { type: "incoming", from: phone, callId });
        send(ws, { type: "ringing", to, callId });
        console.log(`  🔔 ${phone} → ${to} (${callId.slice(0,8)})`);
        break;
      }

      // ── 接听 ──
      case "accept": {
        const call = calls.get(msg.callId);
        if (!call) return;
        call.status = "connected";
        const fromWs = users.get(call.from)?.ws;
        if (fromWs) send(fromWs, { type: "accepted", callId: msg.callId });
        console.log(`  ✅ ${call.from} ↔ ${call.to}`);
        break;
      }

      // ── 拒接 ──
      case "reject": {
        const call = calls.get(msg.callId);
        if (!call) return;
        const fromWs = users.get(call.from)?.ws;
        if (fromWs) send(fromWs, { type: "rejected", callId: msg.callId });
        calls.delete(msg.callId);
        console.log(`  ❌ ${call.from} 拒接`);
        break;
      }

      // ── WebRTC SDP ──
      case "offer": {
        const call = calls.get(msg.callId);
        if (!call) return;
        const toWs = users.get(call.to)?.ws;
        if (toWs) send(toWs, { type: "offer", callId: msg.callId, sdp: msg.sdp, from: call.from });
        break;
      }
      case "answer": {
        const call = calls.get(msg.callId);
        if (!call) return;
        const fromWs = users.get(call.from)?.ws;
        if (fromWs) send(fromWs, { type: "answer", callId: msg.callId, sdp: msg.sdp });
        break;
      }

      // ── ICE ──
      case "ice": {
        const call = calls.get(msg.callId);
        if (!call) return;
        const target = users.get(msg.to === call.from ? call.to : call.from)?.ws;
        if (target) send(target, { type: "ice", callId: msg.callId, candidate: msg.candidate, from: msg.to });
        break;
      }

      // ── 字幕文本 ──
      case "subtitle": {
        const call = calls.get(msg.callId);
        if (!call) return;
        const target = msg.to === call.from ? call.to : call.from;
        const targetWs = users.get(target)?.ws;
        if (targetWs) send(targetWs, { type: "subtitle", callId: msg.callId, text: msg.text, from: msg.to });
        break;
      }

      // ── 挂断 ──
      case "hangup": {
        const call = calls.get(msg.callId);
        if (!call) return;
        const other = call.from === phone ? call.to : call.from;
        const otherWs = users.get(other)?.ws;
        if (otherWs) send(otherWs, { type: "hangup", callId: msg.callId, from: phone });
        calls.delete(msg.callId);
        console.log(`  🔚 ${call.from} ↔ ${call.to}`);
        break;
      }
    }
  });

  ws.on("close", () => {
    if (phone) {
      users.delete(phone);
      // 结束该用户所有通话
      for (const [id, call] of calls) {
        if (call.from === phone || call.to === phone) {
          const otherPhone = call.from === phone ? call.to : call.from;
          const otherWs = users.get(otherPhone)?.ws;
          if (otherWs) send(otherWs, { type: "hangup", callId: id, from: phone });
          calls.delete(id);
        }
      }
      console.log(`  ❌ 离线: ${phone} (${users.size}人)`);
      broadcastOnline();
    }
  });
});
