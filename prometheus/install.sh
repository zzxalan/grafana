#!/bin/bash

# Prometheus 安装脚本
# 从 ../package 目录解压并安装 Prometheus

set -e

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROMETHEUS_DIR="$SCRIPT_DIR"
PACKAGE_DIR="$(dirname "$SCRIPT_DIR")/package"
PROMETHEUS_PACKAGE="prometheus-3.4.1.linux-amd64.tar.gz"

echo "=== Prometheus 安装开始 ==="

# 检查包文件是否存在
if [ ! -f "$PACKAGE_DIR/$PROMETHEUS_PACKAGE" ]; then
    echo "错误: 找不到 Prometheus 安装包 $PACKAGE_DIR/$PROMETHEUS_PACKAGE"
    exit 1
fi

echo "找到 Prometheus 安装包: $PACKAGE_DIR/$PROMETHEUS_PACKAGE"

# 创建临时解压目录
TEMP_DIR="$PROMETHEUS_DIR/temp_extract"
mkdir -p "$TEMP_DIR"

# 解压安装包
echo "正在解压 Prometheus..."
tar -xzf "$PACKAGE_DIR/$PROMETHEUS_PACKAGE" -C "$TEMP_DIR"

# 查看解压后的内容
echo "解压后的内容:"
ls -la "$TEMP_DIR"

# 查找 Prometheus 解压目录
PROMETHEUS_EXTRACT_DIR=$(find "$TEMP_DIR" -name "prometheus-*" -type d | head -1)
if [ -z "$PROMETHEUS_EXTRACT_DIR" ]; then
    echo "错误: 无法找到 Prometheus 解压目录"
    rm -rf "$TEMP_DIR"
    exit 1
fi

echo "找到 Prometheus 解压目录: $PROMETHEUS_EXTRACT_DIR"

# 检查二进制文件
if [ ! -f "$PROMETHEUS_EXTRACT_DIR/prometheus" ]; then
    echo "错误: 无法找到 Prometheus 二进制文件"
    rm -rf "$TEMP_DIR"
    exit 1
fi

if [ ! -f "$PROMETHEUS_EXTRACT_DIR/promtool" ]; then
    echo "错误: 无法找到 Promtool 二进制文件"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# 创建bin目录
echo "创建bin目录..."
mkdir -p "$PROMETHEUS_DIR/bin"

# 复制二进制文件到bin目录
echo "正在安装 Prometheus 二进制文件到 bin 目录..."
cp "$PROMETHEUS_EXTRACT_DIR/prometheus" "$PROMETHEUS_DIR/bin/"
cp "$PROMETHEUS_EXTRACT_DIR/promtool" "$PROMETHEUS_DIR/bin/"
chmod +x "$PROMETHEUS_DIR/bin/prometheus"
chmod +x "$PROMETHEUS_DIR/bin/promtool"

# 复制其他必要文件
if [ -d "$PROMETHEUS_EXTRACT_DIR/console_libraries" ]; then
    echo "复制 console_libraries..."
    cp -r "$PROMETHEUS_EXTRACT_DIR/console_libraries" "$PROMETHEUS_DIR/"
fi

if [ -d "$PROMETHEUS_EXTRACT_DIR/consoles" ]; then
    echo "复制 consoles..."
    cp -r "$PROMETHEUS_EXTRACT_DIR/consoles" "$PROMETHEUS_DIR/"
fi

# 清理临时目录
rm -rf "$TEMP_DIR"

# 创建必要的目录
echo "创建数据目录..."
mkdir -p "$PROMETHEUS_DIR/data"
mkdir -p "$PROMETHEUS_DIR/logs"
mkdir -p "$PROMETHEUS_DIR/rules"

# 检查配置文件
if [ ! -f "$PROMETHEUS_DIR/prometheus.yml" ]; then
    echo "警告: 配置文件 prometheus.yml 不存在"
else
    echo "配置文件已存在: prometheus.yml"
fi

echo "=== Prometheus 安装完成 ==="
echo "二进制文件位置: $PROMETHEUS_DIR/bin/prometheus"
echo "工具文件位置: $PROMETHEUS_DIR/bin/promtool"
echo "配置文件位置: $PROMETHEUS_DIR/prometheus.yml"
echo "数据目录: $PROMETHEUS_DIR/data"
echo "日志目录: $PROMETHEUS_DIR/logs"
echo "规则目录: $PROMETHEUS_DIR/rules"
echo ""
echo "使用 './service.sh' 启动 Prometheus 服务" 