/**
 * TalkTranslate v2 信令服务器 — 轻量测试版
 *
 * 仅依赖 Redis（不依赖 PostgreSQL），适合快速测试。
 * 用户数据存储在 Redis 中，重启会丢失。
 */
import { WebSocketServer } from "ws";
import { v4 as uuid } from "uuid";
import express from "express";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import { createServer } from "http";
import { createClient } from "redis";

const PORT = process.env.PORT || 3459;
const INSTANCE_ID = process.env.INSTANCE_ID || `node_${Date.now()}_${Math.random().toString(36).slice(2,6)}`;
const JWT_SECRET = process.env.JWT_SECRET || "talktranslate_dev_secret_2026";

// ── Redis ──
const redisUrl = process.env.REDIS_URL || "redis://localhost:6379";
const redis = createClient({ url: redisUrl });
const sub = redis.duplicate();
const pub = redis.duplicate();

await redis.connect();
await sub.connect();
await pub.connect();

const KEY = {
  online: "tt:online",
  calls: "tt:calls",
  users: "tt:users",       // Hash: phone → JSON {id,username,phone,password_hash}
  instance: `tt:inst:${INSTANCE_ID}`,
};

// ── JWT ──
function authenticateToken(req, res, next) {
  const authHeader = req.headers["authorization"];
  const token = authHeader && authHeader.split(" ")[1];
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

app.get("/api/health", (req, res) => {
  res.json({ ok: true, instance: INSTANCE_ID, uptime: process.uptime() });
});

app.post("/api/register", async (req, res) => {
  try {
    const { username, phone, password } = req.body;
    if (!username || !phone || !password)
      return res.json({ ok: false, message: "缺少必填字段" });
    if (password.length < 6)
      return res.json({ ok: false, message: "密码至少6位" });

    const exist = await redis.hGet(KEY.users, phone);
    if (exist) return res.json({ ok: false, message: "该手机号已注册" });

    const hash = await bcrypt.hash(password, 10);
    const id = uuid();
    await redis.hSet(KEY.users, phone, JSON.stringify({
      id, username, phone,
      password: hash,
      createdAt: Date.now(),
    }));

    const token = generateToken({ id, username, phone });
    console.log(`  📝 注册: ${username} (${phone})`);
    res.json({ ok: true, token, user: { id, username, phone } });
  } catch (e) {
    console.error("注册错误:", e.message);
    res.json({ ok: false, message: "注册失败" });
  }
});

app.post("/api/login", async (req, res) => {
  try {
    const { phone, password } = req.body;
    if (!phone || !password)
      return res.json({ ok: false, message: "缺少手机号或密码" });

    const raw = await redis.hGet(KEY.users, phone);
    if (!raw) return res.json({ ok: false, message: "用户不存在" });

    const user = JSON.parse(raw);
    const match = await bcrypt.compare(password, user.password);
    if (!match) return res.json({ ok: false, message: "密码错误" });

    const token = generateToken({ id: user.id, username: user.username, phone: user.phone });
    console.log(`  🔑 登录: ${user.username} (${phone})`);
    res.json({ ok: true, token, user: { id: user.id, username: user.username, phone: user.phone } });
  } catch (e) {
    console.error("登录错误:", e.message);
    res.json({ ok: false, message: "登录失败" });
  }
});

// ── 密码重置 ──
const RESET_CODE_PREFIX = "tt:reset:";  // Key: tt:reset:<phone> → code

app.post("/api/forgot-password", async (req, res) => {
  try {
    const { phone } = req.body;
    if (!phone) return res.json({ ok: false, message: "缺少手机号" });

    const raw = await redis.hGet(KEY.users, phone);
    if (!raw) return res.json({ ok: false, message: "该手机号未注册" });

    // 生成 6 位重置码
    const code = String(Math.floor(100000 + Math.random() * 900000));
    await redis.setEx(`${RESET_CODE_PREFIX}${phone}`, 600, code);  // 10 分钟有效

    console.log(`  🔐 密码重置码: ${phone} → ${code}`);
    // 测试阶段直接把验证码返回（生产环境应发短信/邮件）
    res.json({ ok: true, message: "重置码已发送", code });
  } catch (e) {
    console.error("忘记密码错误:", e.message);
    res.json({ ok: false, message: "操作失败" });
  }
});

app.post("/api/reset-password", async (req, res) => {
  try {
    const { phone, code, newPassword } = req.body;
    if (!phone || !code || !newPassword)
      return res.json({ ok: false, message: "缺少必填字段" });
    if (newPassword.length < 6)
      return res.json({ ok: false, message: "密码至少6位" });

    // 验证重置码
    const stored = await redis.get(`${RESET_CODE_PREFIX}${phone}`);
    if (!stored || stored !== code)
      return res.json({ ok: false, message: "验证码无效或已过期" });

    // 更新密码
    const raw = await redis.hGet(KEY.users, phone);
    if (!raw) return res.json({ ok: false, message: "用户不存在" });

    const user = JSON.parse(raw);
    const hash = await bcrypt.hash(newPassword, 10);
    user.password = hash;
    await redis.hSet(KEY.users, phone, JSON.stringify(user));

    // 清除重置码
    await redis.del(`${RESET_CODE_PREFIX}${phone}`);

    const token = generateToken({ id: user.id, username: user.username, phone: user.phone });
    console.log(`  🔑 密码已重置: ${phone}`);
    res.json({ ok: true, message: "密码已重置", token });
  } catch (e) {
    console.error("重置密码错误:", e.message);
    res.json({ ok: false, message: "操作失败" });
  }
});

// ── 获取用户信息 ──
app.get("/api/me", authenticateToken, async (req, res) => {
  res.json({ ok: true, user: req.user });
});

// ── WebSocket ──
const server = createServer(app);
const wss = new WebSocketServer({ server });

// 内存状态
const clients = new Map();  // phone → {ws, user}
const calls = new Map();    // callId → {from, to, sdp, state}

wss.on("connection", (ws, req) => {
  let authed = false;
  let phone = null;
  let userInfo = null;

  ws.on("message", async (raw) => {
    try {
      const msg = JSON.parse(raw.toString());

      // ── Auth ──
      if (msg.type === "auth") {
        try {
          const decoded = jwt.verify(msg.token, JWT_SECRET);
          authed = true;
          userInfo = decoded;
          ws.send(JSON.stringify({ type: "auth_ok", user: decoded }));
        } catch (e) {
          ws.send(JSON.stringify({ type: "auth_error", message: "token 无效" }));
        }
        return;
      }

      if (!authed && msg.type !== "register") {
        ws.send(JSON.stringify({ type: "error", message: "请先 auth" }));
        return;
      }

      // ── Register ──
      if (msg.type === "register") {
        phone = msg.phone;
        
        // 踢掉旧连接
        const old = clients.get(phone);
        if (old && old.ws !== ws) {
          old.ws.close();
        }
        clients.set(phone, { ws, user: userInfo });
        
        await redis.hSet(KEY.online, phone, INSTANCE_ID);
        await pub.publish("tt:online", JSON.stringify({ type: "online", phone, instance: INSTANCE_ID }));
        
        ws.send(JSON.stringify({ type: "registered", phone, instance: INSTANCE_ID }));
        
        // 广播在线列表
        await _broadcastOnline();
        return;
      }

      if (!phone) {
        ws.send(JSON.stringify({ type: "error", message: "请先 register" }));
        return;
      }

      // ── 通话信令 ──
      switch (msg.type) {
        case "call": {
          const callId = uuid();
          calls.set(callId, { from: phone, to: msg.to, state: "ringing" });
          const target = clients.get(msg.to);
          if (target) {
            target.ws.send(JSON.stringify({ type: "incoming", callId, from: phone }));
          }
          ws.send(JSON.stringify({ type: "calling", callId }));
          break;
        }
        case "accept": {
          const call = calls.get(msg.callId);
          if (call) {
            call.state = "accepted";
            const target = clients.get(call.to);
            if (target) target.ws.send(JSON.stringify({ type: "accepted", callId: msg.callId }));
          }
          break;
        }
        case "reject": {
          const call = calls.get(msg.callId);
          if (call) {
            const target = clients.get(call.to);
            if (target) target.ws.send(JSON.stringify({ type: "rejected", callId: msg.callId }));
            calls.delete(msg.callId);
          }
          break;
        }
        case "offer":
        case "answer": {
          const target = clients.get(msg.to);
          if (target) {
            target.ws.send(JSON.stringify({
              type: msg.type, callId: msg.callId, sdp: msg.sdp, from: phone,
            }));
          }
          break;
        }
        case "ice": {
          const target = clients.get(msg.to);
          if (target) {
            target.ws.send(JSON.stringify({
              type: "ice", callId: msg.callId, candidate: msg.candidate, from: phone,
            }));
          }
          break;
        }
        case "subtitle": {
          const target = clients.get(msg.to);
          if (target) {
            target.ws.send(JSON.stringify({
              type: "subtitle", callId: msg.callId,
              text: msg.text, translated: msg.translated, from: phone,
            }));
          }
          break;
        }
        case "hangup": {
          const call = calls.get(msg.callId);
          if (call) {
            const target = clients.get(call.to);
            if (target) target.ws.send(JSON.stringify({ type: "hangup", callId: msg.callId }));
            calls.delete(msg.callId);
          }
          break;
        }
        case "ping": {
          ws.send(JSON.stringify({ type: "pong", time: msg.time }));
          break;
        }
      }
    } catch (e) {
      ws.send(JSON.stringify({ type: "error", message: `消息解析失败: ${e.message}` }));
    }
  });

  ws.on("close", async () => {
    if (phone) {
      clients.delete(phone);
      await redis.hDel(KEY.online, phone);
      await _broadcastOnline();
    }
  });
});

async function _broadcastOnline() {
  const online = await redis.hKeys(KEY.online);
  const msg = JSON.stringify({ type: "online", users: online });
  for (const [p, c] of clients) {
    try { c.ws.send(msg); } catch (_) {}
  }
}

server.listen(PORT, "0.0.0.0", () => {
  console.log(`\n  🗣️  TalkTranslate 信令服务器 (轻量版)`);
  console.log(`  🌐  http://0.0.0.0:${PORT}`);
  console.log(`  🔑  JWT_SECRET: ${JWT_SECRET.slice(0,8)}...`);
  console.log(`  📡  Redis: ${redisUrl}`);
  console.log(`  \n  ${new Date().toISOString()}\n`);
});
