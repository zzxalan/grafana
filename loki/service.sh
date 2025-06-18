#!/bin/bash

# Loki 服务管理脚本
# 支持 start, stop, restart, status 操作
# 管理 Loki 和 Promtail 两个服务

set -e

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOKI_DIR="$SCRIPT_DIR"
LOKI_BIN="$LOKI_DIR/bin/loki"
PROMTAIL_BIN="$LOKI_DIR/bin/promtail"
LOKI_CONFIG="$LOKI_DIR/loki.yaml"
PROMTAIL_CONFIG="$LOKI_DIR/promtail.yaml"
LOKI_PID="$LOKI_DIR/loki.pid"
PROMTAIL_PID="$LOKI_DIR/promtail.pid"
LOKI_LOG="$LOKI_DIR/logs/loki.log"
PROMTAIL_LOG="$LOKI_DIR/logs/promtail.log"

# 创建日志目录
mkdir -p "$LOKI_DIR/logs"

# 检查二进制文件是否存在
check_binary() {
    if [ ! -f "$LOKI_BIN" ]; then
        echo "错误: Loki 二进制文件不存在: $LOKI_BIN"
        echo "请先运行 './install.sh' 安装 Loki"
        exit 1
    fi
    
    if [ ! -f "$PROMTAIL_BIN" ]; then
        echo "错误: Promtail 二进制文件不存在: $PROMTAIL_BIN"
        echo "请先运行 './install.sh' 安装 Promtail"
        exit 1
    fi
}

# 检查配置文件是否存在
check_config() {
    if [ ! -f "$LOKI_CONFIG" ]; then
        echo "错误: Loki 配置文件不存在: $LOKI_CONFIG"
        exit 1
    fi
    
    if [ ! -f "$PROMTAIL_CONFIG" ]; then
        echo "错误: Promtail 配置文件不存在: $PROMTAIL_CONFIG"
        exit 1
    fi
}

# 检查 Loki 进程是否运行
is_loki_running() {
    if [ -f "$LOKI_PID" ]; then
        local pid=$(cat "$LOKI_PID")
        if ps -p "$pid" > /dev/null 2>&1; then
            return 0
        else
            rm -f "$LOKI_PID"
            return 1
        fi
    fi
    return 1
}

# 检查 Promtail 进程是否运行
is_promtail_running() {
    if [ -f "$PROMTAIL_PID" ]; then
        local pid=$(cat "$PROMTAIL_PID")
        if ps -p "$pid" > /dev/null 2>&1; then
            return 0
        else
            rm -f "$PROMTAIL_PID"
            return 1
        fi
    fi
    return 1
}

# 启动 Loki
start_loki() {
    echo "=== 启动 Loki 服务 ==="
    
    check_binary
    check_config
    
    if is_loki_running; then
        echo "Loki 服务已经在运行中 (PID: $(cat "$LOKI_PID"))"
    else
        echo "启动 Loki..."
        echo "二进制文件: $LOKI_BIN"
        echo "配置文件: $LOKI_CONFIG"
        echo "日志文件: $LOKI_LOG"
        
        # 启动 Loki 服务
        nohup "$LOKI_BIN" -config.file="$LOKI_CONFIG" > "$LOKI_LOG" 2>&1 &
        local pid=$!
        echo $pid > "$LOKI_PID"
        
        # 等待服务启动
        sleep 3
        
        if is_loki_running; then
            echo "Loki 服务启动成功 (PID: $pid)"
            echo "HTTP API: http://localhost:3100"
            echo "gRPC API: localhost:9095"
        else
            echo "错误: Loki 服务启动失败"
            echo "请检查日志文件: $LOKI_LOG"
            exit 1
        fi
    fi
}

# 启动 Promtail
start_promtail() {
    echo "=== 启动 Promtail 服务 ==="
    
    if is_promtail_running; then
        echo "Promtail 服务已经在运行中 (PID: $(cat "$PROMTAIL_PID"))"
    else
        echo "启动 Promtail..."
        echo "二进制文件: $PROMTAIL_BIN"
        echo "配置文件: $PROMTAIL_CONFIG"
        echo "日志文件: $PROMTAIL_LOG"
        
        # 启动 Promtail 服务
        nohup "$PROMTAIL_BIN" -config.file="$PROMTAIL_CONFIG" > "$PROMTAIL_LOG" 2>&1 &
        local pid=$!
        echo $pid > "$PROMTAIL_PID"
        
        # 等待服务启动
        sleep 2
        
        if is_promtail_running; then
            echo "Promtail 服务启动成功 (PID: $pid)"
            echo "HTTP API: http://localhost:9080"
        else
            echo "错误: Promtail 服务启动失败"
            echo "请检查日志文件: $PROMTAIL_LOG"
            exit 1
        fi
    fi
}

# 启动所有服务
start_all() {
    start_loki
    echo ""
    start_promtail
}

# 停止 Loki
stop_loki() {
    echo "=== 停止 Loki 服务 ==="
    
    if ! is_loki_running; then
        echo "Loki 服务未运行"
        return 0
    fi
    
    local pid=$(cat "$LOKI_PID")
    echo "停止 Loki 服务 (PID: $pid)..."
    
    kill "$pid"
    
    # 等待进程停止
    local count=0
    while is_loki_running && [ $count -lt 10 ]; do
        sleep 1
        count=$((count + 1))
    done
    
    if is_loki_running; then
        echo "强制停止 Loki 服务..."
        kill -9 "$pid"
        sleep 1
    fi
    
    rm -f "$LOKI_PID"
    echo "Loki 服务已停止"
}

# 停止 Promtail
stop_promtail() {
    echo "=== 停止 Promtail 服务 ==="
    
    if ! is_promtail_running; then
        echo "Promtail 服务未运行"
        return 0
    fi
    
    local pid=$(cat "$PROMTAIL_PID")
    echo "停止 Promtail 服务 (PID: $pid)..."
    
    kill "$pid"
    
    # 等待进程停止
    local count=0
    while is_promtail_running && [ $count -lt 10 ]; do
        sleep 1
        count=$((count + 1))
    done
    
    if is_promtail_running; then
        echo "强制停止 Promtail 服务..."
        kill -9 "$pid"
        sleep 1
    fi
    
    rm -f "$PROMTAIL_PID"
    echo "Promtail 服务已停止"
}

# 停止所有服务
stop_all() {
    stop_promtail
    echo ""
    stop_loki
}

# 重启所有服务
restart_all() {
    echo "=== 重启 Loki 服务 ==="
    stop_all
    sleep 2
    start_all
}

# 查看状态
status_all() {
    echo "=== Loki 服务状态 ==="
    
    # Loki 状态
    echo "--- Loki ---"
    if is_loki_running; then
        local pid=$(cat "$LOKI_PID")
        echo "状态: 运行中"
        echo "PID: $pid"
        echo "二进制文件: $LOKI_BIN"
        echo "配置文件: $LOKI_CONFIG"
        echo "日志文件: $LOKI_LOG"
        echo "HTTP API: http://localhost:3100"
        echo "gRPC API: localhost:9095"
        
        # 显示进程信息
        echo "进程信息:"
        ps -p "$pid" -o pid,ppid,user,start,time,command 2>/dev/null || echo "无法获取进程信息"
    else
        echo "状态: 未运行"
    fi
    
    echo ""
    
    # Promtail 状态
    echo "--- Promtail ---"
    if is_promtail_running; then
        local pid=$(cat "$PROMTAIL_PID")
        echo "状态: 运行中"
        echo "PID: $pid"
        echo "二进制文件: $PROMTAIL_BIN"
        echo "配置文件: $PROMTAIL_CONFIG"
        echo "日志文件: $PROMTAIL_LOG"
        echo "HTTP API: http://localhost:9080"
        
        # 显示进程信息
        echo "进程信息:"
        ps -p "$pid" -o pid,ppid,user,start,time,command 2>/dev/null || echo "无法获取进程信息"
    else
        echo "状态: 未运行"
    fi
}

# 查看日志
logs_all() {
    echo "=== Loki 服务日志 ==="
    
    # Loki 日志
    echo "--- Loki 日志 ---"
    if [ -f "$LOKI_LOG" ]; then
        echo "日志文件: $LOKI_LOG"
        echo "最近的日志:"
        echo "----------------------------------------"
        tail -n 25 "$LOKI_LOG"
    else
        echo "日志文件不存在: $LOKI_LOG"
    fi
    
    echo ""
    
    # Promtail 日志
    echo "--- Promtail 日志 ---"
    if [ -f "$PROMTAIL_LOG" ]; then
        echo "日志文件: $PROMTAIL_LOG"
        echo "最近的日志:"
        echo "----------------------------------------"
        tail -n 25 "$PROMTAIL_LOG"
    else
        echo "日志文件不存在: $PROMTAIL_LOG"
    fi
}

# 主函数
main() {
    case "${1:-start}" in
        start)
            start_all
            ;;
        stop)
            stop_all
            ;;
        restart)
            restart_all
            ;;
        status)
            status_all
            ;;
        logs)
            logs_all
            ;;
        start-loki)
            start_loki
            ;;
        start-promtail)
            start_promtail
            ;;
        stop-loki)
            stop_loki
            ;;
        stop-promtail)
            stop_promtail
            ;;
        *)
            echo "用法: $0 {start|stop|restart|status|logs|start-loki|start-promtail|stop-loki|stop-promtail}"
            echo ""
            echo "命令说明:"
            echo "  start        - 启动所有服务 (Loki + Promtail)"
            echo "  stop         - 停止所有服务"
            echo "  restart      - 重启所有服务"
            echo "  status       - 查看服务状态"
            echo "  logs         - 查看服务日志"
            echo "  start-loki   - 仅启动 Loki 服务"
            echo "  start-promtail - 仅启动 Promtail 服务"
            echo "  stop-loki    - 仅停止 Loki 服务"
            echo "  stop-promtail  - 仅停止 Promtail 服务"
            exit 1
            ;;
    esac
}

main "$@" 