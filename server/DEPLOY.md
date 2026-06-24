# TalkTranslate 信令服务器部署指南

## 方式一：直接部署 (VPS)

```bash
# 1. 上传到服务器
scp -r talktranslate/server user@your-vps:~/talktranslate-server

# 2. 安装依赖
cd ~/talktranslate-server
npm install

# 3. 启动（前台）
node index.js

# 4. 后台运行（推荐）
npm install -g pm2
pm2 start index.js --name talktranslate
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
  --restart unless-stopped \
  talktranslate-server

# 3. 查看日志
docker logs -f talktranslate
```

## 方式三：docker-compose

```bash
# 项目根目录执行
docker compose -f server/docker-compose.yml up -d
```

## 防火墙配置

```bash
# 开放 3459 端口
ufw allow 3459
# 或云服务商安全组添加规则: TCP 3459
```

## 验证部署

```bash
# 服务器端应显示
curl -i -H "Upgrade: websocket" -H "Connection: Upgrade" http://localhost:3459
# 输出: 📞 TalkTranslate v2 信令服务器
#       ⚡ ws://0.0.0.0:3459
```

## 客户端配置

手机端 App 中：
1. 打开 App → 连续点击 Logo 5 次 → 开发者模式
2. 输入服务器地址: `ws://<你的VPS公网IP>:3459`
3. 或使用 WSS: `wss://<你的域名>:3459`

## 生产环境建议

| 配置 | 建议 |
|------|------|
| 反向代理 | Nginx + WSS (WebSocket Secure) |
| SSL | Let's Encrypt (certbot) |
| 监控 | PM2 + 系统监控 |
| 日志 | PM2 日志 + logrotate |
| 端口 | 443 (WSS) / 3459 (WS) |
