#!/bin/bash

# Prometheus 服务管理脚本
# 支持 start, stop, restart, status 操作

set -e

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROMETHEUS_DIR="$SCRIPT_DIR"
PROMETHEUS_BIN="$PROMETHEUS_DIR/bin/prometheus"
PROMETHEUS_CONFIG="$PROMETHEUS_DIR/prometheus.yml"
PROMETHEUS_PID="$PROMETHEUS_DIR/prometheus.pid"
PROMETHEUS_LOG="$PROMETHEUS_DIR/logs/prometheus.log"

# 创建日志目录
mkdir -p "$PROMETHEUS_DIR/logs"

# 检查二进制文件是否存在
check_binary() {
    if [ ! -f "$PROMETHEUS_BIN" ]; then
        echo "错误: Prometheus 二进制文件不存在: $PROMETHEUS_BIN"
        echo "请先运行 './install.sh' 安装 Prometheus"
        exit 1
    fi
}

# 检查配置文件是否存在
check_config() {
    if [ ! -f "$PROMETHEUS_CONFIG" ]; then
        echo "错误: Prometheus 配置文件不存在: $PROMETHEUS_CONFIG"
        exit 1
    fi
}

# 检查进程是否运行
is_running() {
    if [ -f "$PROMETHEUS_PID" ]; then
        local pid=$(cat "$PROMETHEUS_PID")
        if ps -p "$pid" > /dev/null 2>&1; then
            return 0
        else
            rm -f "$PROMETHEUS_PID"
            return 1
        fi
    fi
    return 1
}

# 启动 Prometheus
start_prometheus() {
    echo "=== 启动 Prometheus 服务 ==="
    
    check_binary
    check_config
    
    if is_running; then
        echo "Prometheus 服务已经在运行中 (PID: $(cat "$PROMETHEUS_PID"))"
        return 0
    fi
    
    echo "启动 Prometheus..."
    echo "二进制文件: $PROMETHEUS_BIN"
    echo "配置文件: $PROMETHEUS_CONFIG"
    echo "日志文件: $PROMETHEUS_LOG"
    echo "数据目录: $PROMETHEUS_DIR/data"
    
    # 启动 Prometheus 服务
    nohup "$PROMETHEUS_BIN" \
        --config.file="$PROMETHEUS_CONFIG" \
        --storage.tsdb.path="$PROMETHEUS_DIR/data" \
        --web.console.templates="$PROMETHEUS_DIR/consoles" \
        --web.console.libraries="$PROMETHEUS_DIR/console_libraries" \
        --web.listen-address="0.0.0.0:9090" \
        --web.enable-lifecycle \
        --web.enable-admin-api \
        --storage.tsdb.retention.time=15d \
        --storage.tsdb.retention.size=10GB \
        > "$PROMETHEUS_LOG" 2>&1 &
    
    local pid=$!
    echo $pid > "$PROMETHEUS_PID"
    
    # 等待服务启动
    sleep 3
    
    if is_running; then
        echo "Prometheus 服务启动成功 (PID: $pid)"
        echo "Web UI: http://localhost:9090"
        echo "API: http://localhost:9090/api/v1/"
        echo "Metrics: http://localhost:9090/metrics"
    else
        echo "错误: Prometheus 服务启动失败"
        echo "请检查日志文件: $PROMETHEUS_LOG"
        exit 1
    fi
}

# 停止 Prometheus
stop_prometheus() {
    echo "=== 停止 Prometheus 服务 ==="
    
    if ! is_running; then
        echo "Prometheus 服务未运行"
        return 0
    fi
    
    local pid=$(cat "$PROMETHEUS_PID")
    echo "停止 Prometheus 服务 (PID: $pid)..."
    
    kill "$pid"
    
    # 等待进程停止
    local count=0
    while is_running && [ $count -lt 10 ]; do
        sleep 1
        count=$((count + 1))
    done
    
    if is_running; then
        echo "强制停止 Prometheus 服务..."
        kill -9 "$pid"
        sleep 1
    fi
    
    rm -f "$PROMETHEUS_PID"
    echo "Prometheus 服务已停止"
}

# 重启 Prometheus
restart_prometheus() {
    echo "=== 重启 Prometheus 服务 ==="
    stop_prometheus
    sleep 2
    start_prometheus
}

# 查看状态
status_prometheus() {
    echo "=== Prometheus 服务状态 ==="
    
    if is_running; then
        local pid=$(cat "$PROMETHEUS_PID")
        echo "状态: 运行中"
        echo "PID: $pid"
        echo "二进制文件: $PROMETHEUS_BIN"
        echo "配置文件: $PROMETHEUS_CONFIG"
        echo "日志文件: $PROMETHEUS_LOG"
        echo "数据目录: $PROMETHEUS_DIR/data"
        echo "Web UI: http://localhost:9090"
        echo "API: http://localhost:9090/api/v1/"
        echo "Metrics: http://localhost:9090/metrics"
        
        # 显示进程信息
        echo ""
        echo "进程信息:"
        ps -p "$pid" -o pid,ppid,user,start,time,command 2>/dev/null || echo "无法获取进程信息"
        
        # 显示存储使用情况
        if [ -d "$PROMETHEUS_DIR/data" ]; then
            echo ""
            echo "存储使用情况:"
            du -sh "$PROMETHEUS_DIR/data" 2>/dev/null || echo "无法获取存储信息"
        fi
    else
        echo "状态: 未运行"
    fi
}

# 查看日志
logs_prometheus() {
    echo "=== Prometheus 服务日志 ==="
    
    if [ -f "$PROMETHEUS_LOG" ]; then
        echo "日志文件: $PROMETHEUS_LOG"
        echo "最近的日志:"
        echo "----------------------------------------"
        tail -n 50 "$PROMETHEUS_LOG"
    else
        echo "日志文件不存在: $PROMETHEUS_LOG"
    fi
}

# 重载配置
reload_prometheus() {
    echo "=== 重载 Prometheus 配置 ==="
    
    if ! is_running; then
        echo "错误: Prometheus 服务未运行"
        return 1
    fi
    
    echo "发送重载信号到 Prometheus..."
    curl -X POST http://localhost:9090/-/reload
    
    if [ $? -eq 0 ]; then
        echo "配置重载成功"
    else
        echo "配置重载失败，请检查配置文件格式"
        return 1
    fi
}

# 验证配置
validate_config() {
    echo "=== 验证 Prometheus 配置 ==="
    
    check_binary
    check_config
    
    echo "验证配置文件: $PROMETHEUS_CONFIG"
    "$PROMETHEUS_DIR/bin/promtool" check config "$PROMETHEUS_CONFIG"
    
    if [ $? -eq 0 ]; then
        echo "配置文件验证通过"
    else
        echo "配置文件验证失败"
        return 1
    fi
}

# 主函数
main() {
    case "${1:-start}" in
        start)
            start_prometheus
            ;;
        stop)
            stop_prometheus
            ;;
        restart)
            restart_prometheus
            ;;
        status)
            status_prometheus
            ;;
        logs)
            logs_prometheus
            ;;
        reload)
            reload_prometheus
            ;;
        validate)
            validate_config
            ;;
        *)
            echo "用法: $0 {start|stop|restart|status|logs|reload|validate}"
            echo ""
            echo "命令说明:"
            echo "  start    - 启动 Prometheus 服务"
            echo "  stop     - 停止 Prometheus 服务"
            echo "  restart  - 重启 Prometheus 服务"
            echo "  status   - 查看服务状态"
            echo "  logs     - 查看服务日志"
            echo "  reload   - 重载配置文件"
            echo "  validate - 验证配置文件"
            exit 1
            ;;
    esac
}

main "$@" 