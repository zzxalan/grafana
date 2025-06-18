#!/bin/bash

# Loki 安装脚本
# 从 ../package 目录解压并安装 Loki 和 Promtail

set -e

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOKI_DIR="$SCRIPT_DIR"
PACKAGE_DIR="$(dirname "$SCRIPT_DIR")/package"
LOKI_PACKAGE="loki-linux-amd64.zip"
PROMTAIL_PACKAGE="promtail-linux-amd64.zip"

echo "=== Loki 安装开始 ==="

# 检查包文件是否存在
if [ ! -f "$PACKAGE_DIR/$LOKI_PACKAGE" ]; then
    echo "错误: 找不到 Loki 安装包 $PACKAGE_DIR/$LOKI_PACKAGE"
    exit 1
fi

if [ ! -f "$PACKAGE_DIR/$PROMTAIL_PACKAGE" ]; then
    echo "错误: 找不到 Promtail 安装包 $PACKAGE_DIR/$PROMTAIL_PACKAGE"
    exit 1
fi

echo "找到 Loki 安装包: $PACKAGE_DIR/$LOKI_PACKAGE"
echo "找到 Promtail 安装包: $PACKAGE_DIR/$PROMTAIL_PACKAGE"

# 创建临时解压目录
TEMP_DIR="$LOKI_DIR/temp_extract"
mkdir -p "$TEMP_DIR"

# 解压 Loki
echo "正在解压 Loki..."
unzip -q "$PACKAGE_DIR/$LOKI_PACKAGE" -d "$TEMP_DIR"

# 解压 Promtail
echo "正在解压 Promtail..."
unzip -q "$PACKAGE_DIR/$PROMTAIL_PACKAGE" -d "$TEMP_DIR"

# 查看解压后的内容
echo "解压后的内容:"
ls -la "$TEMP_DIR"

# 查找 loki 二进制文件
LOKI_BINARY=""
if [ -f "$TEMP_DIR/loki-linux-amd64" ]; then
    LOKI_BINARY="$TEMP_DIR/loki-linux-amd64"
    echo "找到 Loki 二进制文件: $LOKI_BINARY"
else
    # 查找在子目录中的二进制文件
    LOKI_BINARY=$(find "$TEMP_DIR" -name "*loki*" -type f -executable | head -1)
    if [ -n "$LOKI_BINARY" ]; then
        echo "找到 Loki 二进制文件: $LOKI_BINARY"
    else
        echo "错误: 无法找到 Loki 二进制文件"
        echo "解压后的目录结构:"
        find "$TEMP_DIR" -type f -name "*loki*" -o -name "*" | head -20
        rm -rf "$TEMP_DIR"
        exit 1
    fi
fi

# 查找 promtail 二进制文件
PROMTAIL_BINARY=""
if [ -f "$TEMP_DIR/promtail-linux-amd64" ]; then
    PROMTAIL_BINARY="$TEMP_DIR/promtail-linux-amd64"
    echo "找到 Promtail 二进制文件: $PROMTAIL_BINARY"
else
    # 查找在子目录中的二进制文件
    PROMTAIL_BINARY=$(find "$TEMP_DIR" -name "*promtail*" -type f -executable | head -1)
    if [ -n "$PROMTAIL_BINARY" ]; then
        echo "找到 Promtail 二进制文件: $PROMTAIL_BINARY"
    else
        echo "错误: 无法找到 Promtail 二进制文件"
        echo "解压后的目录结构:"
        find "$TEMP_DIR" -type f -name "*promtail*" -o -name "*" | head -20
        rm -rf "$TEMP_DIR"
        exit 1
    fi
fi

# 创建bin目录
echo "创建bin目录..."
mkdir -p "$LOKI_DIR/bin"

# 复制二进制文件到bin目录
echo "正在安装 Loki 二进制文件到 bin 目录..."
cp "$LOKI_BINARY" "$LOKI_DIR/bin/loki"
chmod +x "$LOKI_DIR/bin/loki"

echo "正在安装 Promtail 二进制文件到 bin 目录..."
cp "$PROMTAIL_BINARY" "$LOKI_DIR/bin/promtail"
chmod +x "$LOKI_DIR/bin/promtail"

# 清理临时目录
rm -rf "$TEMP_DIR"

# 创建必要的目录
echo "创建数据目录..."
mkdir -p "$LOKI_DIR/data/loki"
mkdir -p "$LOKI_DIR/data/wal"
mkdir -p "$LOKI_DIR/data/chunks"
mkdir -p "$LOKI_DIR/logs"

# 检查配置文件
if [ ! -f "$LOKI_DIR/loki.yaml" ]; then
    echo "警告: 配置文件 loki.yaml 不存在"
else
    echo "配置文件已存在: loki.yaml"
fi

if [ ! -f "$LOKI_DIR/promtail.yaml" ]; then
    echo "警告: 配置文件 promtail.yaml 不存在"
else
    echo "配置文件已存在: promtail.yaml"
fi

echo "=== Loki 安装完成 ==="
echo "Loki 二进制文件位置: $LOKI_DIR/bin/loki"
echo "Promtail 二进制文件位置: $LOKI_DIR/bin/promtail"
echo "配置文件位置: $LOKI_DIR/loki.yaml, $LOKI_DIR/promtail.yaml"
echo "数据目录: $LOKI_DIR/data"
echo "日志目录: $LOKI_DIR/logs"
echo ""
echo "使用 './service.sh' 启动 Loki 服务" 