#!/bin/bash

# Grafana 服务管理脚本
# 支持 start, stop, restart, status 操作

set -e

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GRAFANA_DIR="$SCRIPT_DIR"
GRAFANA_BIN="$GRAFANA_DIR/bin/grafana-server"
GRAFANA_CONFIG="$GRAFANA_DIR/grafana.ini"
GRAFANA_PID="$GRAFANA_DIR/grafana.pid"
GRAFANA_LOG="$GRAFANA_DIR/logs/grafana.log"

# 创建日志目录
mkdir -p "$GRAFANA_DIR/logs"

# 检查二进制文件是否存在
check_binary() {
    if [ ! -f "$GRAFANA_BIN" ]; then
        echo "错误: Grafana 二进制文件不存在: $GRAFANA_BIN"
        echo "请先运行 './install.sh' 安装 Grafana"
        exit 1
    fi
}

# 检查配置文件是否存在
check_config() {
    if [ ! -f "$GRAFANA_CONFIG" ]; then
        echo "错误: Grafana 配置文件不存在: $GRAFANA_CONFIG"
        exit 1
    fi
}

# 检查进程是否运行
is_running() {
    if [ -f "$GRAFANA_PID" ]; then
        local pid=$(cat "$GRAFANA_PID")
        if ps -p "$pid" > /dev/null 2>&1; then
            return 0
        else
            rm -f "$GRAFANA_PID"
            return 1
        fi
    fi
    return 1
}

# 启动 Grafana
start_grafana() {
    echo "=== 启动 Grafana 服务 ==="
    
    check_binary
    check_config
    
    if is_running; then
        echo "Grafana 服务已经在运行中 (PID: $(cat "$GRAFANA_PID"))"
        return 0
    fi
    
    echo "启动 Grafana..."
    echo "二进制文件: $GRAFANA_BIN"
    echo "配置文件: $GRAFANA_CONFIG"
    echo "日志文件: $GRAFANA_LOG"
    
    # 启动 Grafana 服务
    nohup "$GRAFANA_BIN" --config="$GRAFANA_CONFIG" --homepath="$GRAFANA_DIR" > "$GRAFANA_LOG" 2>&1 &
    local pid=$!
    echo $pid > "$GRAFANA_PID"
    
    # 等待服务启动
    sleep 5
    
    if is_running; then
        echo "Grafana 服务启动成功 (PID: $pid)"
        echo "Web UI: http://localhost:3000"
        echo "默认用户名: admin"
        echo "默认密码: admin"
        echo ""
        echo "仪表盘已自动加载，可在Web UI中查看"
        echo "仪表盘目录: $GRAFANA_DIR/dashboards"
    else
        echo "错误: Grafana 服务启动失败"
        echo "请检查日志文件: $GRAFANA_LOG"
        exit 1
    fi
}

# 停止 Grafana
stop_grafana() {
    echo "=== 停止 Grafana 服务 ==="
    
    if ! is_running; then
        echo "Grafana 服务未运行"
        return 0
    fi
    
    local pid=$(cat "$GRAFANA_PID")
    echo "停止 Grafana 服务 (PID: $pid)..."
    
    kill "$pid"
    
    # 等待进程停止
    local count=0
    while is_running && [ $count -lt 10 ]; do
        sleep 1
        count=$((count + 1))
    done
    
    if is_running; then
        echo "强制停止 Grafana 服务..."
        kill -9 "$pid"
        sleep 1
    fi
    
    rm -f "$GRAFANA_PID"
    echo "Grafana 服务已停止"
}

# 重启 Grafana
restart_grafana() {
    echo "=== 重启 Grafana 服务 ==="
    stop_grafana
    sleep 2
    start_grafana
}

# 查看状态
status_grafana() {
    echo "=== Grafana 服务状态 ==="
    
    if is_running; then
        local pid=$(cat "$GRAFANA_PID")
        echo "状态: 运行中"
        echo "PID: $pid"
        echo "二进制文件: $GRAFANA_BIN"
        echo "配置文件: $GRAFANA_CONFIG"
        echo "日志文件: $GRAFANA_LOG"
        echo "Web UI: http://localhost:3000"
        echo "默认用户名: admin"
        echo "默认密码: admin"
        echo "仪表盘目录: $GRAFANA_DIR/dashboards"
        
        # 显示进程信息
        echo ""
        echo "进程信息:"
        ps -p "$pid" -o pid,ppid,user,start,time,command 2>/dev/null || echo "无法获取进程信息"
    else
        echo "状态: 未运行"
    fi
}

# 查看日志
logs_grafana() {
    echo "=== Grafana 服务日志 ==="
    
    if [ -f "$GRAFANA_LOG" ]; then
        echo "日志文件: $GRAFANA_LOG"
        echo "最近的日志:"
        echo "----------------------------------------"
        tail -n 50 "$GRAFANA_LOG"
    else
        echo "日志文件不存在: $GRAFANA_LOG"
    fi
}

# 主函数
main() {
    case "${1:-start}" in
        start)
            start_grafana
            ;;
        stop)
            stop_grafana
            ;;
        restart)
            restart_grafana
            ;;
        status)
            status_grafana
            ;;
        logs)
            logs_grafana
            ;;
        *)
            echo "用法: $0 {start|stop|restart|status|logs}"
            echo ""
            echo "命令说明:"
            echo "  start   - 启动 Grafana 服务"
            echo "  stop    - 停止 Grafana 服务"
            echo "  restart - 重启 Grafana 服务"
            echo "  status  - 查看服务状态"
            echo "  logs    - 查看服务日志"
            exit 1
            ;;
    esac
}

main "$@"
