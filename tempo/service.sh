#!/bin/bash

# Tempo 服务管理脚本
# 支持 start, stop, restart, status 操作

set -e

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPO_DIR="$SCRIPT_DIR"
TEMPO_BIN="$TEMPO_DIR/bin/tempo"
TEMPO_CONFIG="$TEMPO_DIR/tempo.yaml"
TEMPO_PID="$TEMPO_DIR/tempo.pid"
TEMPO_LOG="$TEMPO_DIR/logs/tempo.log"

# 创建日志目录
mkdir -p "$TEMPO_DIR/logs"

# 检查二进制文件是否存在
check_binary() {
    if [ ! -f "$TEMPO_BIN" ]; then
        echo "错误: Tempo 二进制文件不存在: $TEMPO_BIN"
        echo "请先运行 './install.sh' 安装 Tempo"
        exit 1
    fi
}

# 检查配置文件是否存在
check_config() {
    if [ ! -f "$TEMPO_CONFIG" ]; then
        echo "错误: Tempo 配置文件不存在: $TEMPO_CONFIG"
        exit 1
    fi
}

# 检查进程是否运行
is_running() {
    if [ -f "$TEMPO_PID" ]; then
        local pid=$(cat "$TEMPO_PID")
        if ps -p "$pid" > /dev/null 2>&1; then
            return 0
        else
            rm -f "$TEMPO_PID"
            return 1
        fi
    fi
    return 1
}

# 启动 Tempo
start_tempo() {
    echo "=== 启动 Tempo 服务 ==="
    
    check_binary
    check_config
    
    if is_running; then
        echo "Tempo 服务已经在运行中 (PID: $(cat "$TEMPO_PID"))"
        return 0
    fi
    
    echo "启动 Tempo..."
    echo "二进制文件: $TEMPO_BIN"
    echo "配置文件: $TEMPO_CONFIG"
    echo "日志文件: $TEMPO_LOG"
    
    # 启动 Tempo 服务
    nohup "$TEMPO_BIN" -config.file="$TEMPO_CONFIG" > "$TEMPO_LOG" 2>&1 &
    local pid=$!
    echo $pid > "$TEMPO_PID"
    
    # 等待服务启动
    sleep 3
    
    if is_running; then
        echo "Tempo 服务启动成功 (PID: $pid)"
        echo "Web UI: http://localhost:3200"
        echo "OTLP gRPC: localhost:4317"
        echo "OTLP HTTP: localhost:4318"
    else
        echo "错误: Tempo 服务启动失败"
        echo "请检查日志文件: $TEMPO_LOG"
        exit 1
    fi
}

# 停止 Tempo
stop_tempo() {
    echo "=== 停止 Tempo 服务 ==="
    
    if ! is_running; then
        echo "Tempo 服务未运行"
        return 0
    fi
    
    local pid=$(cat "$TEMPO_PID")
    echo "停止 Tempo 服务 (PID: $pid)..."
    
    kill "$pid"
    
    # 等待进程停止
    local count=0
    while is_running && [ $count -lt 10 ]; do
        sleep 1
        count=$((count + 1))
    done
    
    if is_running; then
        echo "强制停止 Tempo 服务..."
        kill -9 "$pid"
        sleep 1
    fi
    
    rm -f "$TEMPO_PID"
    echo "Tempo 服务已停止"
}

# 重启 Tempo
restart_tempo() {
    echo "=== 重启 Tempo 服务 ==="
    stop_tempo
    sleep 2
    start_tempo
}

# 查看状态
status_tempo() {
    echo "=== Tempo 服务状态 ==="
    
    if is_running; then
        local pid=$(cat "$TEMPO_PID")
        echo "状态: 运行中"
        echo "PID: $pid"
        echo "二进制文件: $TEMPO_BIN"
        echo "配置文件: $TEMPO_CONFIG"
        echo "日志文件: $TEMPO_LOG"
        echo "Web UI: http://localhost:3200"
        echo "OTLP gRPC: localhost:4317"
        echo "OTLP HTTP: localhost:4318"
        
        # 显示进程信息
        echo ""
        echo "进程信息:"
        ps -p "$pid" -o pid,ppid,user,start,time,command 2>/dev/null || echo "无法获取进程信息"
    else
        echo "状态: 未运行"
    fi
}

# 查看日志
logs_tempo() {
    echo "=== Tempo 服务日志 ==="
    
    if [ -f "$TEMPO_LOG" ]; then
        echo "日志文件: $TEMPO_LOG"
        echo "最近的日志:"
        echo "----------------------------------------"
        tail -n 50 "$TEMPO_LOG"
    else
        echo "日志文件不存在: $TEMPO_LOG"
    fi
}

# 主函数
main() {
    case "${1:-start}" in
        start)
            start_tempo
            ;;
        stop)
            stop_tempo
            ;;
        restart)
            restart_tempo
            ;;
        status)
            status_tempo
            ;;
        logs)
            logs_tempo
            ;;
        *)
            echo "用法: $0 {start|stop|restart|status|logs}"
            echo ""
            echo "命令说明:"
            echo "  start   - 启动 Tempo 服务"
            echo "  stop    - 停止 Tempo 服务"
            echo "  restart - 重启 Tempo 服务"
            echo "  status  - 查看服务状态"
            echo "  logs    - 查看服务日志"
            exit 1
            ;;
    esac
}

main "$@"
