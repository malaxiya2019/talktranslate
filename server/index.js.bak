/**
 * TalkTranslate v2 分布式信令服务器
 *
 * 架构:
 *   Redis  — 共享状态 (在线用户/通话/Pub/Sub)
 *   PG     — 用户持久化
 *   多实例 — 通过 Redis Pub/Sub 互通
 *   JWT    — WebSocket + REST 认证
 */
import { WebSocketServer } from "ws";
import { v4 as uuid } from "uuid";
import express from "express";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import { createServer } from "http";
import { createClient } from "redis";
import pg from "pg";

const { Pool } = pg;

const PORT = process.env.PORT || 3459;
const INSTANCE_ID = process.env.INSTANCE_ID || `node_${Date.now()}_${Math.random().toString(36).slice(2,6)}`;
const JWT_SECRET = process.env.JWT_SECRET || "talktranslate_dev_secret_2026";

// ── PostgreSQL ──
const pool = new Pool({
  host: process.env.PG_HOST || "/tmp",
  port: parseInt(process.env.PG_PORT || "5432"),
  database: process.env.PG_DB || "talktranslate",
  user: process.env.PG_USER || process.env.USER || "u0_a328",
  password: process.env.PG_PASSWORD || "",
  max: parseInt(process.env.PG_POOL_MAX || "20"),
  idleTimeoutMillis: parseInt(process.env.PG_POOL_IDLE || "30000"),
  connectionTimeoutMillis: parseInt(process.env.PG_CONNECT_TIMEOUT || "5000"),
});

// ── Redis ──
const redis = createClient({ url: process.env.REDIS_URL || "redis://localhost:6380" });
const sub = redis.duplicate();
const pub = redis.duplicate();

const KEY = {
  online: "tt:online",       // Hash: phone → instanceId
  calls: "tt:calls",         // Hash: callId → JSON
  instance: `tt:inst:${INSTANCE_ID}`, // Key: instance heartbeat
};

// ── JWT 中间件 ──
function authenticateToken(req, res, next) {
  const authHeader = req.headers["authorization"];
  const token = authHeader && authHeader.split(" ")[1]; // Bearer <token>
  if (!token) return res.status(401).json({ ok: false, message: "缺少 token" });

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) return res.status(403).json({ ok: false, message: "token 无效或已过期" });
    req.user = user;
    next();
  });
}

function generateToken(payload) {
  return jwt.sign(payload, JWT_SECRET, { expiresIn: "7d" });
}

// ── Express API ──
const app = express();
app.use(express.json());
app.use((req, res, next) => {
  res.header("Access-Control-Allow-Origin", "*");
  res.header("Access-Control-Allow-Headers", "Content-Type, Authorization");
  res.header("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  if (req.method === "OPTIONS") return res.sendStatus(200);
  next();
});

// 健康检查
app.get("/api/health", (req, res) => {
  res.json({ ok: true, instance: INSTANCE_ID, uptime: process.uptime() });
});

// 注册
app.post("/api/register", async (req, res) => {
  try {
    const { username, phone, password } = req.body;
    if (!username || !phone || !password)
      return res.json({ ok: false, message: "缺少必填字段" });
    if (password.length < 6)
      return res.json({ ok: false, message: "密码至少6位" });

    const exist = await pool.query("SELECT id FROM users WHERE phone = $1", [phone]);
    if (exist.rows.length > 0)
      return res.json({ ok: false, message: "该手机号已注册" });

    const hash = await bcrypt.hash(password, 10);
    const id = uuid();
    await pool.query(
      "INSERT INTO users (id, username, phone, password, created_at) VALUES ($1,$2,$3,$4,$5)",
      [id, username, phone, hash, Date.now()]
    );
    console.log(`  📝 注册: ${username} (${phone})`);

    const token = generateToken({ id, username, phone });
    res.json({ ok: true, message: "注册成功", user: { id, username, phone }, token });
  } catch (e) {
    console.error("注册错误:", e.message);
    res.json({ ok: false, message: "服务器错误" });
  }
});

// 登录（返回 JWT token）
app.post("/api/login", async (req, res) => {
  try {
    const { phone, password } = req.body;
    if (!phone || !password)
      return res.json({ ok: false, message: "缺少手机号或密码" });

    const result = await pool.query("SELECT * FROM users WHERE phone = $1", [phone]);
    if (result.rows.length === 0)
      return res.json({ ok: false, message: "手机号未注册" });

    const user = result.rows[0];
    const match = await bcrypt.compare(password, user.password);
    if (!match)
      return res.json({ ok: false, message: "密码错误" });

    console.log(`  🔑 登录: ${user.username} (${phone})`);

    const token = generateToken({ id: user.id, username: user.username, phone });
    res.json({ ok: true, message: "登录成功", user: { id: user.id, username: user.username, phone }, token });
  } catch (e) {
    console.error("登录错误:", e.message);
    res.json({ ok: false, message: "服务器错误" });
  }
});

// 受保护的 API：获取当前用户信息
app.get("/api/me", authenticateToken, (req, res) => {
  res.json({ ok: true, user: req.user });
});

// ── HTTP + WebSocket ──
const server = createServer(app);
const wss = new WebSocketServer({ server });

// 本实例本地用户: phone → { ws, user }
const localUsers = new Map();

function send(ws, data) {
  try { ws.send(JSON.stringify(data)); } catch {}
}

// 向指定手机号的用户发送消息（先查本地，再通过 Redis Pub 跨实例）
async function routeMessage(phone, msg) {
  const entry = localUsers.get(phone);
  if (entry) { send(entry.ws, msg); return true; }

  const instId = await redis.hGet(KEY.online, phone);
  if (!instId || instId === INSTANCE_ID) return false;

  await pub.publish("tt:msg", JSON.stringify({ to: phone, msg }));
  return true;
}

// ── 订阅跨实例消息 ──
sub.subscribe("tt:msg", (raw) => {
  try {
    const { to, msg } = JSON.parse(raw);
    const entry = localUsers.get(to);
    if (entry) send(entry.ws, msg);
  } catch {}
});

// ── 心跳：每 10s 刷新本实例在线状态 ──
const heartbeatTimer = setInterval(async () => {
  try {
    await redis.set(KEY.instance, Date.now().toString(), { EX: 30 });
  } catch {}
}, 10000);

// ── 优雅关闭 ──
async function shutdown(signal) {
  console.log(`\n  🛑 收到 ${signal}，正在关闭...`);
  clearInterval(heartbeatTimer);

  // 摘除本实例在线用户
  for (const [phone] of localUsers) {
    await redis.hDel(KEY.online, phone);
  }
  localUsers.clear();

  // 摘除本实例心跳
  await redis.del(KEY.instance);

  // 关闭 Redis 连接
  try { await pub.quit(); } catch {}
  try { await sub.quit(); } catch {}
  try { await redis.quit(); } catch {}

  // 关闭 HTTP/WS 服务器
  server.close(() => {
    console.log("  ✅ 服务器已关闭");
    pool.end().then(() => process.exit(0));
  });

  // 超时强制退出
  setTimeout(() => process.exit(1), 5000);
}

process.on("SIGTERM", () => shutdown("SIGTERM"));
process.on("SIGINT", () => shutdown("SIGINT"));

// ── WebSocket 连接 ──
wss.on("error", (err) => console.error("  ❌ 服务器异常:", err.message));

wss.on("connection", (ws) => {
  let phone = null;
  let authenticated = false;

  ws.on("error", (err) => {
    console.error(`  ❌ 连接异常: ${phone || "?"}`, err.message);
  });

  ws.on("message", async (raw) => {
    let msg;
    try { msg = JSON.parse(raw.toString()); } catch { return send(ws, { type: "error", message: "无效JSON" }); }

    // 第一条消息必须是 auth（携带 JWT token）
    if (!authenticated) {
      if (msg.type !== "auth") {
        return send(ws, { type: "error", message: "请先发送 auth 消息进行认证" });
      }
      try {
        const decoded = jwt.verify(msg.token, JWT_SECRET);
        authenticated = true;
        ws.user = decoded;
        send(ws, { type: "auth_ok", user: { id: decoded.id, username: decoded.username, phone: decoded.phone } });
        console.log(`  ✅ 认证成功: ${decoded.username} (${decoded.phone})`);
        return;
      } catch {
        return send(ws, { type: "error", message: "token 无效或已过期" });
      }
    }

    switch (msg.type) {
      case "ping":
        send(ws, { type: "pong", time: msg.time, serverTime: Date.now() });
        break;

      case "register":
        phone = msg.phone;
        if (!phone) return send(ws, { type: "error", message: "缺少手机号" });

        // 验证 token 中的 phone 与注册的 phone 一致
        if (ws.user && ws.user.phone !== phone) {
          return send(ws, { type: "error", message: "手机号与 token 不匹配" });
        }

        localUsers.set(phone, { ws, user: ws.user });
        await redis.hSet(KEY.online, phone, INSTANCE_ID);
        send(ws, { type: "registered", phone, instance: INSTANCE_ID });
        console.log(`  📱 在线: ${phone} @ ${INSTANCE_ID.slice(0,12)}`);

        const allOnline = await redis.hKeys(KEY.online);
        const list = allOnline.filter(Boolean);
        for (const [, { ws: localWs }] of localUsers) send(localWs, { type: "online", users: list });
        break;

      case "call": {
        const to = msg.to;
        if (!to) return send(ws, { type: "error", message: "缺少对方手机号" });
        if (to === phone) return send(ws, { type: "error", message: "不能呼叫自己" });
        const callId = uuid();
        await redis.hSet(KEY.calls, callId, JSON.stringify({ from: phone, to, status: "ringing" }));
        await redis.expire(KEY.calls, 300);
        const delivered = await routeMessage(to, { type: "incoming", from: phone, callId });
        if (!delivered) return send(ws, { type: "error", message: "对方不在线" });
        send(ws, { type: "ringing", to, callId });
        console.log(`  🔔 ${phone} → ${to} [${INSTANCE_ID.slice(0,8)}]`);
        break;
      }

      case "accept": {
        const rawCall = await redis.hGet(KEY.calls, msg.callId);
        if (!rawCall) return;
        const call = JSON.parse(rawCall);
        call.status = "connected";
        await redis.hSet(KEY.calls, msg.callId, JSON.stringify(call));
        routeMessage(call.from, { type: "accepted", callId: msg.callId });
        console.log(`  ✅ ${call.from} ↔ ${call.to}`);
        break;
      }

      case "reject": {
        const rawCall = await redis.hGet(KEY.calls, msg.callId);
        if (!rawCall) return;
        const call = JSON.parse(rawCall);
        routeMessage(call.from, { type: "rejected", callId: msg.callId });
        await redis.hDel(KEY.calls, msg.callId);
        console.log(`  ❌ ${call.from} 拒接`);
        break;
      }

      case "offer": {
        const rawCall = await redis.hGet(KEY.calls, msg.callId);
        if (!rawCall) return;
        const call = JSON.parse(rawCall);
        routeMessage(call.to, { type: "offer", callId: msg.callId, sdp: msg.sdp, from: call.from });
        break;
      }
      case "answer": {
        const rawCall = await redis.hGet(KEY.calls, msg.callId);
        if (!rawCall) return;
        const call = JSON.parse(rawCall);
        routeMessage(call.from, { type: "answer", callId: msg.callId, sdp: msg.sdp });
        break;
      }

      case "ice": {
        const rawCall = await redis.hGet(KEY.calls, msg.callId);
        if (!rawCall) return;
        const call = JSON.parse(rawCall);
        const target = msg.to === call.from ? call.to : call.from;
        routeMessage(target, { type: "ice", callId: msg.callId, candidate: msg.candidate, from: msg.to });
        break;
      }

      case "subtitle": {
        const rawCall = await redis.hGet(KEY.calls, msg.callId);
        if (!rawCall) return;
        const call = JSON.parse(rawCall);
        const target = msg.to === call.from ? call.to : call.from;
        routeMessage(target, {
          type: "subtitle", callId: msg.callId,
          text: msg.text, translated: msg.translated || "", from: msg.to,
        });
        break;
      }

      case "hangup": {
        const rawCall = await redis.hGet(KEY.calls, msg.callId);
        if (!rawCall) return;
        const call = JSON.parse(rawCall);
        const other = call.from === phone ? call.to : call.from;
        routeMessage(other, { type: "hangup", callId: msg.callId, from: phone });
        await redis.hDel(KEY.calls, msg.callId);
        console.log(`  🔚 ${call.from} ↔ ${call.to}`);
        break;
      }
    }
  });

  ws.on("close", async () => {
    if (phone) {
      localUsers.delete(phone);
      await redis.hDel(KEY.online, phone);
      const allCalls = await redis.hGetAll(KEY.calls);
      for (const [id, raw] of Object.entries(allCalls)) {
        const call = JSON.parse(raw);
        if (call.from === phone || call.to === phone) {
          const other = call.from === phone ? call.to : call.from;
          routeMessage(other, { type: "hangup", callId: id, from: phone });
          await redis.hDel(KEY.calls, id);
        }
      }
      console.log(`  ❌ 离线: ${phone} (${localUsers.size}人)`);
      const allOnline = await redis.hKeys(KEY.online);
      for (const [, { ws: localWs }] of localUsers) send(localWs, { type: "online", users: allOnline.filter(Boolean) });
    }
  });
});

// ── 启动 ──
async function main() {
  await redis.connect();
  await sub.connect();
  await pub.connect();

  server.listen(PORT, () => {
    console.log(`\n  📞 TalkTranslate v2 分布式信令服务器`);
    console.log(`  🆔 实例: ${INSTANCE_ID.slice(0,16)}`);
    console.log(`  ⚡ WS : ws://0.0.0.0:${PORT}`);
    console.log(`  🌐 API: http://0.0.0.0:${PORT}/api`);
    console.log(`  🔐 JWT: ${JWT_SECRET === "talktranslate_dev_secret_2026" ? "开发密钥 (请在生产环境设置 JWT_SECRET)" : "已配置"}`);
    console.log(`  🗄️  PG + Redis\n`);
  });
}

main().catch((e) => {
  console.error("启动失败:", e);
  process.exit(1);
});
