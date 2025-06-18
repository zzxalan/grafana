#!/bin/bash

# Node Exporter 服务管理脚本
# 支持 start, stop, restart, status 操作

set -e

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NODE_EXPORTER_DIR="$SCRIPT_DIR"
NODE_EXPORTER_BIN="$NODE_EXPORTER_DIR/bin/node_exporter"
NODE_EXPORTER_PID="$NODE_EXPORTER_DIR/node_exporter.pid"
NODE_EXPORTER_LOG="$NODE_EXPORTER_DIR/logs/node_exporter.log"
NODE_EXPORTER_PORT="9100"

# 创建日志目录
mkdir -p "$NODE_EXPORTER_DIR/logs"

# 检查二进制文件是否存在
check_binary() {
    if [ ! -f "$NODE_EXPORTER_BIN" ]; then
        echo "错误: Node Exporter 二进制文件不存在: $NODE_EXPORTER_BIN"
        echo "请先运行 './install.sh' 安装 Node Exporter"
        exit 1
    fi
}

# 检查进程是否运行
is_running() {
    if [ -f "$NODE_EXPORTER_PID" ]; then
        local pid=$(cat "$NODE_EXPORTER_PID")
        if ps -p "$pid" > /dev/null 2>&1; then
            return 0
        else
            rm -f "$NODE_EXPORTER_PID"
            return 1
        fi
    fi
    return 1
}

# 启动 Node Exporter
start_node_exporter() {
    echo "=== 启动 Node Exporter 服务 ==="
    
    check_binary
    
    if is_running; then
        echo "Node Exporter 服务已经在运行中 (PID: $(cat "$NODE_EXPORTER_PID"))"
        return 0
    fi
    
    echo "启动 Node Exporter..."
    echo "二进制文件: $NODE_EXPORTER_BIN"
    echo "日志文件: $NODE_EXPORTER_LOG"
    echo "监听端口: $NODE_EXPORTER_PORT"
    
    # 启动 Node Exporter 服务
    nohup "$NODE_EXPORTER_BIN" \
        --web.listen-address=":$NODE_EXPORTER_PORT" \
        --log.level=info \
        > "$NODE_EXPORTER_LOG" 2>&1 &
    local pid=$!
    echo $pid > "$NODE_EXPORTER_PID"
    
    # 等待服务启动
    sleep 3
    
    if is_running; then
        echo "Node Exporter 服务启动成功 (PID: $pid)"
        echo "Metrics URL: http://localhost:$NODE_EXPORTER_PORT/metrics"
    else
        echo "错误: Node Exporter 服务启动失败"
        echo "请检查日志文件: $NODE_EXPORTER_LOG"
        exit 1
    fi
}

# 停止 Node Exporter
stop_node_exporter() {
    echo "=== 停止 Node Exporter 服务 ==="
    
    if ! is_running; then
        echo "Node Exporter 服务未运行"
        return 0
    fi
    
    local pid=$(cat "$NODE_EXPORTER_PID")
    echo "停止 Node Exporter 服务 (PID: $pid)..."
    
    kill "$pid"
    
    # 等待进程停止
    local count=0
    while is_running && [ $count -lt 10 ]; do
        sleep 1
        count=$((count + 1))
    done
    
    if is_running; then
        echo "强制停止 Node Exporter 服务..."
        kill -9 "$pid"
        sleep 1
    fi
    
    rm -f "$NODE_EXPORTER_PID"
    echo "Node Exporter 服务已停止"
}

# 重启 Node Exporter
restart_node_exporter() {
    echo "=== 重启 Node Exporter 服务 ==="
    stop_node_exporter
    sleep 2
    start_node_exporter
}

# 查看状态
status_node_exporter() {
    echo "=== Node Exporter 服务状态 ==="
    
    if is_running; then
        local pid=$(cat "$NODE_EXPORTER_PID")
        echo "状态: 运行中"
        echo "PID: $pid"
        echo "二进制文件: $NODE_EXPORTER_BIN"
        echo "日志文件: $NODE_EXPORTER_LOG"
        echo "监听端口: $NODE_EXPORTER_PORT"
        echo "Metrics URL: http://localhost:$NODE_EXPORTER_PORT/metrics"
        
        # 显示进程信息
        echo ""
        echo "进程信息:"
        ps -p "$pid" -o pid,ppid,user,start,time,command 2>/dev/null || echo "无法获取进程信息"
    else
        echo "状态: 未运行"
    fi
}

# 查看日志
logs_node_exporter() {
    echo "=== Node Exporter 服务日志 ==="
    
    if [ -f "$NODE_EXPORTER_LOG" ]; then
        echo "日志文件: $NODE_EXPORTER_LOG"
        echo "最近的日志:"
        echo "----------------------------------------"
        tail -n 50 "$NODE_EXPORTER_LOG"
    else
        echo "日志文件不存在: $NODE_EXPORTER_LOG"
    fi
}

# 主函数
main() {
    case "${1:-start}" in
        start)
            start_node_exporter
            ;;
        stop)
            stop_node_exporter
            ;;
        restart)
            restart_node_exporter
            ;;
        status)
            status_node_exporter
            ;;
        logs)
            logs_node_exporter
            ;;
        *)
            echo "用法: $0 {start|stop|restart|status|logs}"
            echo ""
            echo "命令说明:"
            echo "  start   - 启动 Node Exporter 服务"
            echo "  stop    - 停止 Node Exporter 服务"
            echo "  restart - 重启 Node Exporter 服务"
            echo "  status  - 查看服务状态"
            echo "  logs    - 查看服务日志"
            exit 1
            ;;
    esac
}

main "$@" 