/**
 * TalkTranslate v2 信令服务器
 * WebSocket + REST API (注册/登录)
 */
import { WebSocketServer } from "ws";
import { v4 as uuid } from "uuid";
import express from "express";
import bcrypt from "bcryptjs";
import { readFileSync, writeFileSync, existsSync } from "fs";
import { createServer } from "http";

const PORT = process.env.PORT || 3459;
const HTTP_PORT = process.env.HTTP_PORT || 3460;
const USERS_FILE = new URL("./data/users.json", import.meta.url).pathname;

// ── 用户存储 ──
function loadUsers() {
  try {
    if (existsSync(USERS_FILE)) {
      return JSON.parse(readFileSync(USERS_FILE, "utf-8"));
    }
  } catch {}
  return [];
}

function saveUsers(users) {
  writeFileSync(USERS_FILE, JSON.stringify(users, null, 2));
}

// ── REST API ──
const app = express();
app.use(express.json());

// CORS
app.use((req, res, next) => {
  res.header("Access-Control-Allow-Origin", "*");
  res.header("Access-Control-Allow-Headers", "Content-Type");
  res.header("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  if (req.method === "OPTIONS") return res.sendStatus(200);
  next();
});

// 注册
app.post("/api/register", async (req, res) => {
  const { username, phone, password } = req.body;
  if (!username || !phone || !password) {
    return res.json({ ok: false, message: "缺少必填字段" });
  }
  if (password.length < 6) {
    return res.json({ ok: false, message: "密码至少6位" });
  }
  const users = loadUsers();
  if (users.find((u) => u.phone === phone)) {
    return res.json({ ok: false, message: "该手机号已注册" });
  }
  const hash = await bcrypt.hash(password, 10);
  const user = { id: uuid(), username, phone, password: hash, createdAt: Date.now() };
  users.push(user);
  saveUsers(users);
  console.log(`  📝 新用户注册: ${username} (${phone})`);
  res.json({ ok: true, message: "注册成功", user: { id: user.id, username, phone } });
});

// 登录
app.post("/api/login", async (req, res) => {
  const { phone, password } = req.body;
  if (!phone || !password) {
    return res.json({ ok: false, message: "缺少手机号或密码" });
  }
  const users = loadUsers();
  const user = users.find((u) => u.phone === phone);
  if (!user) {
    return res.json({ ok: false, message: "手机号未注册" });
  }
  const match = await bcrypt.compare(password, user.password);
  if (!match) {
    return res.json({ ok: false, message: "密码错误" });
  }
  console.log(`  🔑 用户登录: ${user.username} (${phone})`);
  res.json({ ok: true, message: "登录成功", user: { id: user.id, username: user.username, phone } });
});

// ── HTTP + WebSocket 同端口 ──
const server = createServer(app);

const wss = new WebSocketServer({ server });

// phone → { ws, registeredAt }
const users = new Map();
// callId → { from, to, status }
const calls = new Map();

console.log(`\n  📞 TalkTranslate v2 信令服务器`);
console.log(`  ⚡ WS : ws://0.0.0.0:${PORT}`);
console.log(`  🌐 API: http://0.0.0.0:${HTTP_PORT || PORT}/api\n`);

function send(ws, data) {
  try { ws.send(JSON.stringify(data)); } catch {}
}

function broadcastOnline() {
  const list = [...users.keys()];
  for (const [, { ws }] of users) send(ws, { type: "online", users: list });
}

// 服务器级错误处理
wss.on("error", (err) => console.error("  ❌ 服务器异常:", err.message));

wss.on("connection", (ws) => {
  let phone = null;

  // 连接级错误处理
  ws.on("error", (err) => {
    if (phone) console.error(`  ❌ 连接异常: ${phone}`, err.message);
    else console.error("  ❌ 连接异常:", err.message);
  });

  ws.on("message", (raw) => {
    let msg;
    try { msg = JSON.parse(raw.toString()); } catch { return send(ws, { type: "error", message: "无效JSON" }); }

    switch (msg.type) {
      case "ping":
        send(ws, { type: "pong", time: msg.time, serverTime: Date.now() });
        break;
      case "register":
        phone = msg.phone;
        if (!phone) return send(ws, { type: "error", message: "缺少手机号" });
        users.set(phone, { ws, at: Date.now() });
        send(ws, { type: "registered", phone });
        console.log(`  ✅ 在线: ${phone} (${users.size}人)`);
        broadcastOnline();
        break;

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

      case "accept": {
        const call = calls.get(msg.callId);
        if (!call) return;
        call.status = "connected";
        const fromWs = users.get(call.from)?.ws;
        if (fromWs) send(fromWs, { type: "accepted", callId: msg.callId });
        console.log(`  ✅ ${call.from} ↔ ${call.to}`);
        break;
      }

      case "reject": {
        const call = calls.get(msg.callId);
        if (!call) return;
        const fromWs = users.get(call.from)?.ws;
        if (fromWs) send(fromWs, { type: "rejected", callId: msg.callId });
        calls.delete(msg.callId);
        console.log(`  ❌ ${call.from} 拒接`);
        break;
      }

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

      case "ice": {
        const call = calls.get(msg.callId);
        if (!call) return;
        const target = users.get(msg.to === call.from ? call.to : call.from)?.ws;
        if (target) send(target, { type: "ice", callId: msg.callId, candidate: msg.candidate, from: msg.to });
        break;
      }

      case "subtitle": {
        const call = calls.get(msg.callId);
        if (!call) return;
        const target = msg.to === call.from ? call.to : call.from;
        const targetWs = users.get(target)?.ws;
        if (targetWs) send(targetWs, {
          type: "subtitle", callId: msg.callId,
          text: msg.text, translated: msg.translated || "",
          from: msg.to,
        });
        break;
      }

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

server.listen(PORT, () => {
  console.log(`  🚀 服务已启动: http://0.0.0.0:${PORT}`);
});
