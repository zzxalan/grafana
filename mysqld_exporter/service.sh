#!/bin/bash

# MySQL Exporter 服务管理脚本
# 支持 start, stop, restart, status 操作

set -e

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MYSQLD_EXPORTER_DIR="$SCRIPT_DIR"
MYSQLD_EXPORTER_BIN="$MYSQLD_EXPORTER_DIR/bin/mysqld_exporter"
MYSQLD_EXPORTER_CONFIG="$MYSQLD_EXPORTER_DIR/my.cnf"
MYSQLD_EXPORTER_PID="$MYSQLD_EXPORTER_DIR/mysqld_exporter.pid"
MYSQLD_EXPORTER_LOG="$MYSQLD_EXPORTER_DIR/logs/mysqld_exporter.log"
MYSQLD_EXPORTER_PORT="9104"

# 创建日志目录
mkdir -p "$MYSQLD_EXPORTER_DIR/logs"

# 检查二进制文件是否存在
check_binary() {
    if [ ! -f "$MYSQLD_EXPORTER_BIN" ]; then
        echo "错误: MySQL Exporter 二进制文件不存在: $MYSQLD_EXPORTER_BIN"
        echo "请先运行 './install.sh' 安装 MySQL Exporter"
        exit 1
    fi
}

# 检查配置文件是否存在
check_config() {
    if [ ! -f "$MYSQLD_EXPORTER_CONFIG" ]; then
        echo "错误: MySQL Exporter 配置文件不存在: $MYSQLD_EXPORTER_CONFIG"
        echo "请先运行 './install.sh' 创建配置文件"
        exit 1
    fi
}

# 检查进程是否运行
is_running() {
    if [ -f "$MYSQLD_EXPORTER_PID" ]; then
        local pid=$(cat "$MYSQLD_EXPORTER_PID")
        if ps -p "$pid" > /dev/null 2>&1; then
            return 0
        else
            rm -f "$MYSQLD_EXPORTER_PID"
            return 1
        fi
    fi
    return 1
}

# 启动 MySQL Exporter
start_mysqld_exporter() {
    echo "=== 启动 MySQL Exporter 服务 ==="
    
    check_binary
    check_config
    
    if is_running; then
        echo "MySQL Exporter 服务已经在运行中 (PID: $(cat "$MYSQLD_EXPORTER_PID"))"
        return 0
    fi
    
    echo "启动 MySQL Exporter..."
    echo "二进制文件: $MYSQLD_EXPORTER_BIN"
    echo "配置文件: $MYSQLD_EXPORTER_CONFIG"
    echo "日志文件: $MYSQLD_EXPORTER_LOG"
    echo "监听端口: $MYSQLD_EXPORTER_PORT"
    
    # 启动 MySQL Exporter 服务
    nohup "$MYSQLD_EXPORTER_BIN" \
        --config.my-cnf="$MYSQLD_EXPORTER_CONFIG" \
        --web.listen-address=":$MYSQLD_EXPORTER_PORT" \
        --log.level=info \
        > "$MYSQLD_EXPORTER_LOG" 2>&1 &
    local pid=$!
    echo $pid > "$MYSQLD_EXPORTER_PID"
    
    # 等待服务启动
    sleep 3
    
    if is_running; then
        echo "MySQL Exporter 服务启动成功 (PID: $pid)"
        echo "Metrics URL: http://localhost:$MYSQLD_EXPORTER_PORT/metrics"
    else
        echo "错误: MySQL Exporter 服务启动失败"
        echo "请检查日志文件: $MYSQLD_EXPORTER_LOG"
        echo "请确认 MySQL 数据库连接配置是否正确"
        exit 1
    fi
}

# 停止 MySQL Exporter
stop_mysqld_exporter() {
    echo "=== 停止 MySQL Exporter 服务 ==="
    
    if ! is_running; then
        echo "MySQL Exporter 服务未运行"
        return 0
    fi
    
    local pid=$(cat "$MYSQLD_EXPORTER_PID")
    echo "停止 MySQL Exporter 服务 (PID: $pid)..."
    
    kill "$pid"
    
    # 等待进程停止
    local count=0
    while is_running && [ $count -lt 10 ]; do
        sleep 1
        count=$((count + 1))
    done
    
    if is_running; then
        echo "强制停止 MySQL Exporter 服务..."
        kill -9 "$pid"
        sleep 1
    fi
    
    rm -f "$MYSQLD_EXPORTER_PID"
    echo "MySQL Exporter 服务已停止"
}

# 重启 MySQL Exporter
restart_mysqld_exporter() {
    echo "=== 重启 MySQL Exporter 服务 ==="
    stop_mysqld_exporter
    sleep 2
    start_mysqld_exporter
}

# 查看状态
status_mysqld_exporter() {
    echo "=== MySQL Exporter 服务状态 ==="
    
    if is_running; then
        local pid=$(cat "$MYSQLD_EXPORTER_PID")
        echo "状态: 运行中"
        echo "PID: $pid"
        echo "二进制文件: $MYSQLD_EXPORTER_BIN"
        echo "配置文件: $MYSQLD_EXPORTER_CONFIG"
        echo "日志文件: $MYSQLD_EXPORTER_LOG"
        echo "监听端口: $MYSQLD_EXPORTER_PORT"
        echo "Metrics URL: http://localhost:$MYSQLD_EXPORTER_PORT/metrics"
        
        # 显示进程信息
        echo ""
        echo "进程信息:"
        ps -p "$pid" -o pid,ppid,user,start,time,command 2>/dev/null || echo "无法获取进程信息"
    else
        echo "状态: 未运行"
    fi
}

# 查看日志
logs_mysqld_exporter() {
    echo "=== MySQL Exporter 服务日志 ==="
    
    if [ -f "$MYSQLD_EXPORTER_LOG" ]; then
        echo "日志文件: $MYSQLD_EXPORTER_LOG"
        echo "最近的日志:"
        echo "----------------------------------------"
        tail -n 50 "$MYSQLD_EXPORTER_LOG"
    else
        echo "日志文件不存在: $MYSQLD_EXPORTER_LOG"
    fi
}

# 主函数
main() {
    case "${1:-start}" in
        start)
            start_mysqld_exporter
            ;;
        stop)
            stop_mysqld_exporter
            ;;
        restart)
            restart_mysqld_exporter
            ;;
        status)
            status_mysqld_exporter
            ;;
        logs)
            logs_mysqld_exporter
            ;;
        *)
            echo "用法: $0 {start|stop|restart|status|logs}"
            echo ""
            echo "命令说明:"
            echo "  start   - 启动 MySQL Exporter 服务"
            echo "  stop    - 停止 MySQL Exporter 服务"
            echo "  restart - 重启 MySQL Exporter 服务"
            echo "  status  - 查看服务状态"
            echo "  logs    - 查看服务日志"
            echo ""
            echo "注意: 请确保已正确配置 config/my.cnf 文件中的数据库连接信息"
            exit 1
            ;;
    esac
}

main "$@" 