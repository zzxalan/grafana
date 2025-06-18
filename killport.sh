#!/bin/bash
if [ -z "$1" ]; then
  echo "用法: $0 端口号"
  exit 1
fi

PORT=$1
PID=$(sudo lsof -t -i:$PORT)

if [ -z "$PID" ]; then
  echo "端口 $PORT 没有被占用"
else
  echo "关闭端口 $PORT 的进程: $PID"
  sudo kill -9 $PID
fi
