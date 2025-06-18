#!/bin/bash

# 监控栈统一服务管理脚本
# 支持管理 Prometheus、Grafana、Loki、Node Exporter、MySQL Exporter、Tempo
# 作者: 监控系统管理员
# 版本: 1.0

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 定义服务模块
declare -A SERVICES=(
    ["prometheus"]="prometheus/service.sh"
    ["grafana"]="grafana/service.sh"
    ["loki"]="loki/service.sh"
    ["node_exporter"]="node_exporter/service.sh"
    ["mysqld_exporter"]="mysqld_exporter/service.sh"
    ["tempo"]="tempo/service.sh"
)

# 定义服务启动顺序（依赖关系）
START_ORDER=("prometheus" "node_exporter" "mysqld_exporter" "tempo" "loki" "grafana")
STOP_ORDER=("grafana" "loki" "tempo" "mysqld_exporter" "node_exporter" "prometheus")

# 打印带颜色的消息
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# 打印标题
print_title() {
    echo ""
    print_message $CYAN "=========================================="
    print_message $CYAN "$1"
    print_message $CYAN "=========================================="
    echo ""
}

# 检查服务脚本是否存在
check_service_script() {
    local service=$1
    local script_path="$SCRIPT_DIR/${SERVICES[$service]}"
    
    if [ ! -f "$script_path" ]; then
        print_message $RED "错误: $service 服务脚本不存在: $script_path"
        return 1
    fi
    
    if [ ! -x "$script_path" ]; then
        chmod +x "$script_path"
    fi
    
    return 0
}

# 执行服务操作
execute_service_action() {
    local service=$1
    local action=$2
    local script_path="$SCRIPT_DIR/${SERVICES[$service]}"
    
    if ! check_service_script "$service"; then
        return 1
    fi
    
    print_message $BLUE "执行: $service $action"
    echo "----------------------------------------"
    
    if ! "$script_path" "$action"; then
        print_message $RED "错误: $service $action 执行失败"
        return 1
    fi
    
    echo ""
    return 0
}

# 启动所有服务
start_all() {
    print_title "启动所有监控服务"
    
    local failed_services=()
    
    for service in "${START_ORDER[@]}"; do
        if ! execute_service_action "$service" "start"; then
            failed_services+=("$service")
        fi
        sleep 2
    done
    
    echo ""
    if [ ${#failed_services[@]} -eq 0 ]; then
        print_message $GREEN "✓ 所有服务启动成功！"
        print_service_urls
    else
        print_message $RED "✗ 以下服务启动失败: ${failed_services[*]}"
        print_message $YELLOW "请检查对应服务的日志文件"
    fi
}

# 停止所有服务
stop_all() {
    print_title "停止所有监控服务"
    
    local failed_services=()
    
    for service in "${STOP_ORDER[@]}"; do
        if ! execute_service_action "$service" "stop"; then
            failed_services+=("$service")
        fi
        sleep 1
    done
    
    echo ""
    if [ ${#failed_services[@]} -eq 0 ]; then
        print_message $GREEN "✓ 所有服务停止成功！"
    else
        print_message $RED "✗ 以下服务停止失败: ${failed_services[*]}"
    fi
}

# 重启所有服务
restart_all() {
    print_title "重启所有监控服务"
    stop_all
    sleep 3
    start_all
}

# 查看所有服务状态
status_all() {
    print_title "监控服务状态概览"
    
    local running_count=0
    local total_count=${#SERVICES[@]}
    
    for service in "${START_ORDER[@]}"; do
        local script_path="$SCRIPT_DIR/${SERVICES[$service]}"
        
        if check_service_script "$service"; then
            print_message $BLUE "[$service]"
            "$script_path" status
            
            # 简单检查服务是否运行（基于status命令的返回码）
            if "$script_path" status >/dev/null 2>&1; then
                running_count=$((running_count + 1))
            fi
        else
            print_message $RED "[$service] 服务脚本不存在"
        fi
        echo ""
    done
    
    print_message $CYAN "服务状态汇总: $running_count/$total_count 个服务正在运行"
}

# 查看所有服务日志
logs_all() {
    print_title "监控服务日志"
    
    for service in "${START_ORDER[@]}"; do
        if check_service_script "$service"; then
            print_message $PURPLE "=== $service 日志 ==="
            execute_service_action "$service" "logs"
        fi
    done
}

# 单个服务操作
service_action() {
    local service=$1
    local action=$2
    
    if [ -z "$service" ] || [ -z "$action" ]; then
        print_message $RED "错误: 请指定服务名称和操作"
        show_help
        exit 1
    fi
    
    if [ -z "${SERVICES[$service]}" ]; then
        print_message $RED "错误: 未知的服务名称: $service"
        print_message $YELLOW "可用的服务: ${!SERVICES[*]}"
        exit 1
    fi
    
    print_title "$service 服务 $action 操作"
    execute_service_action "$service" "$action"
}

# 打印服务访问地址
print_service_urls() {
    print_title "服务访问地址"
    
    cat << EOF
🌐 Web 界面:
  • Grafana:    http://localhost:3000     (用户名: admin, 密码: admin)
  • Prometheus: http://localhost:9090     (监控数据查询)
  • Tempo:      http://localhost:3200     (链路追踪)

📊 API 接口:
  • Prometheus: http://localhost:9090/api/v1/
  • Loki:       http://localhost:3100     (日志查询)
  • Grafana:    http://localhost:3000/api/

📈 Metrics 端点:
  • Node Exporter:  http://localhost:9100/metrics
  • MySQL Exporter: http://localhost:9104/metrics
  • Prometheus:     http://localhost:9090/metrics

🔌 其他端点:
  • Loki gRPC:      localhost:9095
  • Promtail:       http://localhost:9080
  • Tempo OTLP gRPC: localhost:4317
  • Tempo OTLP HTTP: localhost:4318
EOF
}

# 安装所有服务
install_all() {
    print_title "安装所有监控服务"
    
    local failed_installs=()
    local original_dir="$(pwd)"
    
    for service in "${START_ORDER[@]}"; do
        local service_dir="$SCRIPT_DIR/$service"
        local install_script="$service_dir/install.sh"
        
        if [ -f "$install_script" ]; then
            print_message $BLUE "安装 $service..."
            echo "----------------------------------------"
            
            # 使用子shell执行安装，避免路径污染
            (
                cd "$service_dir" || exit 1
                ./install.sh
            )
            
            if [ $? -ne 0 ]; then
                failed_installs+=("$service")
                print_message $RED "错误: $service 安装失败"
            else
                print_message $GREEN "✓ $service 安装成功"
            fi
            echo ""
        else
            print_message $YELLOW "警告: $service 安装脚本不存在: $install_script"
        fi
    done
    
    # 确保返回到原始目录
    cd "$original_dir" || true
    
    if [ ${#failed_installs[@]} -eq 0 ]; then
        print_message $GREEN "✓ 所有服务安装成功！"
        print_message $CYAN "现在可以使用 '$0 start' 启动所有服务"
    else
        print_message $RED "✗ 以下服务安装失败: ${failed_installs[*]}"
    fi
}

# 健康检查
health_check() {
    print_title "监控服务健康检查"
    
    local health_status=0
    
    # 检查端口占用情况
    print_message $BLUE "检查端口占用情况..."
    local ports=("3000" "9090" "3100" "9095" "9080" "9100" "9104" "3200" "4317" "4318")
    
    for port in "${ports[@]}"; do
        if netstat -tuln 2>/dev/null | grep -q ":$port "; then
            print_message $GREEN "✓ 端口 $port 已被占用"
        else
            print_message $YELLOW "⚠ 端口 $port 未被占用"
            health_status=1
        fi
    done
    
    echo ""
    
    # 检查服务响应
    print_message $BLUE "检查服务响应..."
    
    # Prometheus
    if curl -s http://localhost:9090/-/ready >/dev/null 2>&1; then
        print_message $GREEN "✓ Prometheus 响应正常"
    else
        print_message $RED "✗ Prometheus 无响应"
        health_status=1
    fi
    
    # Grafana
    if curl -s http://localhost:3000/api/health >/dev/null 2>&1; then
        print_message $GREEN "✓ Grafana 响应正常"
    else
        print_message $RED "✗ Grafana 无响应"
        health_status=1
    fi
    
    # Loki
    if curl -s http://localhost:3100/ready >/dev/null 2>&1; then
        print_message $GREEN "✓ Loki 响应正常"
    else
        print_message $RED "✗ Loki 无响应"
        health_status=1
    fi
    
    # Node Exporter
    if curl -s http://localhost:9100/metrics >/dev/null 2>&1; then
        print_message $GREEN "✓ Node Exporter 响应正常"
    else
        print_message $RED "✗ Node Exporter 无响应"
        health_status=1
    fi
    
    # MySQL Exporter
    if curl -s http://localhost:9104/metrics >/dev/null 2>&1; then
        print_message $GREEN "✓ MySQL Exporter 响应正常"
    else
        print_message $YELLOW "⚠ MySQL Exporter 无响应（可能是配置问题）"
    fi
    
    # Tempo
    if curl -s http://localhost:3200/ready >/dev/null 2>&1; then
        print_message $GREEN "✓ Tempo 响应正常"
    else
        print_message $RED "✗ Tempo 无响应"
        health_status=1
    fi
    
    echo ""
    if [ $health_status -eq 0 ]; then
        print_message $GREEN "✓ 所有服务健康检查通过！"
    else
        print_message $YELLOW "⚠ 部分服务存在问题，请检查日志"
    fi
}

# 显示帮助信息
show_help() {
    cat << EOF
监控栈统一服务管理脚本

用法: $0 [选项] [服务名] [操作]

全局操作:
  install         安装所有监控服务
  start           启动所有监控服务
  stop            停止所有监控服务
  restart         重启所有监控服务
  status          查看所有服务状态
  logs            查看所有服务日志
  health          健康检查
  urls            显示服务访问地址
  help            显示此帮助信息

单个服务操作:
  $0 <服务名> <操作>

可用服务:
  prometheus      Prometheus 监控服务
  grafana         Grafana 可视化服务
  loki            Loki 日志聚合服务
  node_exporter   Node Exporter 系统监控
  mysqld_exporter MySQL Exporter 数据库监控
  tempo           Tempo 链路追踪服务

可用操作:
  start           启动服务
  stop            停止服务
  restart         重启服务
  status          查看服务状态
  logs            查看服务日志

示例:
  $0 start                    # 启动所有服务
  $0 stop                     # 停止所有服务
  $0 status                   # 查看所有服务状态
  $0 prometheus start         # 启动 Prometheus
  $0 grafana restart          # 重启 Grafana
  $0 health                   # 健康检查
  $0 urls                     # 显示服务地址

注意事项:
  1. 首次使用请先运行 '$0 install' 安装所有服务
  2. 服务启动有依赖顺序，建议使用全局操作
  3. MySQL Exporter 需要先配置数据库连接信息
  4. 默认端口如有冲突，请修改对应配置文件

EOF
}

# 主函数
main() {
    # 检查是否有参数
    if [ $# -eq 0 ]; then
        show_help
        exit 0
    fi
    
    case "$1" in
        install)
            install_all
            ;;
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
        health)
            health_check
            ;;
        urls)
            print_service_urls
            ;;
        help|--help|-h)
            show_help
            ;;
        prometheus|grafana|loki|node_exporter|mysqld_exporter|tempo)
            if [ -z "$2" ]; then
                print_message $RED "错误: 请指定操作 (start|stop|restart|status|logs)"
                exit 1
            fi
            service_action "$1" "$2"
            ;;
        *)
            print_message $RED "错误: 未知的选项或服务: $1"
            show_help
            exit 1
            ;;
    esac
}

# 设置脚本权限
chmod +x "$0" 2>/dev/null || true

# 执行主函数
main "$@"
