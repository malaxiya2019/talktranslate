#!/bin/bash

# ── 自动清理旧进程 ──
PID_FILE="/data/data/com.termux/files/home/.talktranslate_server.pid"
if [ -f "$PID_FILE" ]; then
  OLD_PID=$(cat "$PID_FILE")
  if kill -0 "$OLD_PID" 2>/dev/null; then
    echo "🔄 检测到旧服务器 (PID $OLD_PID)，正在关闭..."
    kill "$OLD_PID" 2>/dev/null
    sleep 2
  fi
fi

# ── 环境变量 ──
export REDIS_URL="redis://localhost:6379"
export PG_HOST="/data/data/com.termux/files/usr/tmp"
export JWT_SECRET="Q749NVbigqgQqcLiEIFpMtisnlyR24OeVphnAGfrH6o="

# ── 启动 ──
cd /data/data/com.termux/files/home/workspace/talktranslate/server
echo "📞 启动 TalkTranslate 信令服务器..."
echo "$BASHPID" > "$PID_FILE"
exec node index.js
