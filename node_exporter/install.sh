#!/bin/bash

# Node Exporter 安装脚本
# 从 ../package 目录解压并安装 Node Exporter

set -e

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NODE_EXPORTER_DIR="$SCRIPT_DIR"
PACKAGE_DIR="$(dirname "$SCRIPT_DIR")/package"
NODE_EXPORTER_PACKAGE="node_exporter-1.9.1.linux-amd64.tar.gz"

echo "=== Node Exporter 安装开始 ==="

# 检查包文件是否存在
if [ ! -f "$PACKAGE_DIR/$NODE_EXPORTER_PACKAGE" ]; then
    echo "错误: 找不到 Node Exporter 安装包 $PACKAGE_DIR/$NODE_EXPORTER_PACKAGE"
    exit 1
fi

echo "找到 Node Exporter 安装包: $PACKAGE_DIR/$NODE_EXPORTER_PACKAGE"

# 创建临时解压目录
TEMP_DIR="$NODE_EXPORTER_DIR/temp_extract"
mkdir -p "$TEMP_DIR"

# 解压安装包
echo "正在解压 Node Exporter..."
tar -xzf "$PACKAGE_DIR/$NODE_EXPORTER_PACKAGE" -C "$TEMP_DIR"

# 查看解压后的内容
echo "解压后的内容:"
ls -la "$TEMP_DIR"

# 查找 node_exporter 二进制文件
NODE_EXPORTER_BINARY=""
if [ -f "$TEMP_DIR/node_exporter" ]; then
    # 二进制文件直接在根目录
    NODE_EXPORTER_BINARY="$TEMP_DIR/node_exporter"
    echo "找到 Node Exporter 二进制文件: $NODE_EXPORTER_BINARY"
else
    # 查找在子目录中的二进制文件
    NODE_EXPORTER_BINARY=$(find "$TEMP_DIR" -name "node_exporter" -type f -executable | head -1)
    if [ -n "$NODE_EXPORTER_BINARY" ]; then
        echo "找到 Node Exporter 二进制文件: $NODE_EXPORTER_BINARY"
    else
        echo "错误: 无法找到 Node Exporter 二进制文件"
        echo "解压后的目录结构:"
        find "$TEMP_DIR" -type f -name "*node_exporter*" -o -name "*" | head -20
        rm -rf "$TEMP_DIR"
        exit 1
    fi
fi

# 创建bin目录
echo "创建bin目录..."
mkdir -p "$NODE_EXPORTER_DIR/bin"

# 复制二进制文件到bin目录
echo "正在安装 Node Exporter 二进制文件到 bin 目录..."
cp "$NODE_EXPORTER_BINARY" "$NODE_EXPORTER_DIR/bin/"
chmod +x "$NODE_EXPORTER_DIR/bin/node_exporter"

# 清理临时目录
rm -rf "$TEMP_DIR"

# 创建必要的目录
echo "创建日志目录..."
mkdir -p "$NODE_EXPORTER_DIR/logs"

echo "=== Node Exporter 安装完成 ==="
echo "二进制文件位置: $NODE_EXPORTER_DIR/bin/node_exporter"
echo "日志目录: $NODE_EXPORTER_DIR/logs"
echo ""
echo "使用 './service.sh' 启动 Node Exporter 服务" 