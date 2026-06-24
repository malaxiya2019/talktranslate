# TalkTranslate 信令服务器部署指南

## 目录
- [方式一：直接部署 (VPS)](#方式一直接部署-vps)
- [方式二：Docker 部署](#方式二docker-部署)
- [方式三：docker-compose (推荐)](#方式三docker-compose-推荐)
- [Nginx 反代 + WSS](#nginx-反代--wss)
- [防火墙配置](#防火墙配置)
- [验证部署](#验证部署)
- [客户端配置](#客户端配置)
- [生产环境建议](#生产环境建议)

---

## 方式一：直接部署 (VPS)

```bash
# 1. 上传到服务器
scp -r talktranslate/server user@your-vps:~/talktranslate-server

# 2. 安装依赖
cd ~/talktranslate-server
npm install

# 3. 启动（前台）
JWT_SECRET=your_strong_secret node index.js

# 4. 后台运行（推荐）
npm install -g pm2
JWT_SECRET=your_strong_secret pm2 start index.js --name talktranslate --env JWT_SECRET=your_strong_secret
pm2 save
pm2 startup
```

## 方式二：Docker 部署

```bash
# 1. 构建镜像
docker build -t talktranslate-server talktranslate/server

# 2. 运行
docker run -d \
  --name talktranslate \
  -p 3459:3459 \
  -e JWT_SECRET=your_strong_secret \
  -e REDIS_URL=redis://your-redis:6380 \
  -e PG_HOST=your-postgres \
  --restart unless-stopped \
  talktranslate-server

# 3. 查看日志
docker logs -f talktranslate
```

## 方式三：docker-compose (推荐)

```bash
# 项目根目录执行（会自动启动 Redis + PostgreSQL + 信令服务器）
docker compose -f server/docker-compose.yml up -d

# 自定义 JWT 密钥
JWT_SECRET=your_strong_secret docker compose -f server/docker-compose.yml up -d

# 查看日志
docker compose -f server/docker-compose.yml logs -f signaling

# 停止
docker compose -f server/docker-compose.yml down
```

## Nginx 反代 + WSS

1. 把 `nginx.conf` 复制到 Nginx 配置目录，修改 `server_name` 和证书路径：

```bash
sudo cp server/nginx.conf /etc/nginx/sites-available/talktranslate
sudo ln -s /etc/nginx/sites-available/talktranslate /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
```

2. 获取 SSL 证书（推荐 Let's Encrypt）：

```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d talktranslate.example.com
```

3. 客户端连接地址变为：`wss://talktranslate.example.com/ws`

## 防火墙配置

```bash
# 开放端口
ufw allow 80
ufw allow 443
# 或云服务商安全组添加规则: TCP 80, 443
```

## 验证部署

```bash
# 健康检查
curl http://localhost:3459/api/health
# 输出: {"ok":true,"instance":"node_...","uptime":...}

# 注册测试用户
curl -X POST http://localhost:3459/api/register \
  -H "Content-Type: application/json" \
  -d '{"username":"test","phone":"13800000000","password":"123456"}'

# 登录获取 JWT token
curl -X POST http://localhost:3459/api/login \
  -H "Content-Type: application/json" \
  -d '{"phone":"13800000000","password":"123456"}'
# 返回中包含 token 字段

# 验证 token
curl http://localhost:3459/api/me \
  -H "Authorization: Bearer <你的token>"
```

## WebSocket 认证流程

客户端连接后，第一条消息必须发送 auth：

```json
{"type": "auth", "token": "<登录时获取的JWT token>"}
```

成功响应：
```json
{"type": "auth_ok", "user": {"id": "...", "username": "...", "phone": "..."}}
```

认证成功后，再发送 `register` 注册手机号在线。

## 客户端配置

手机端 App 中：
1. 打开 App → 连续点击 Logo 5 次 → 开发者模式
2. 输入服务器地址: `ws://<你的VPS公网IP>:3459`
3. 或使用 WSS: `wss://<你的域名>/ws`

## 生产环境建议

| 配置 | 建议 |
|------|------|
| JWT 密钥 | 环境变量 `JWT_SECRET`，至少 32 位随机字符串 |
| 反向代理 | Nginx + WSS (WebSocket Secure) |
| SSL | Let's Encrypt (certbot) |
| 数据库 | PostgreSQL 独立部署（非 Docker）做持久化 |
| Redis | 独立部署 + 密码认证 |
| 监控 | PM2 + 系统监控 |
| 日志 | PM2 日志 + logrotate |
| 端口 | 443 (WSS) / 3459 (WS 内网) |
