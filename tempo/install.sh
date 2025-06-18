#!/bin/bash

# Tempo 安装脚本
# 从 ../package 目录解压并安装 Tempo

set -e

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPO_DIR="$SCRIPT_DIR"
PACKAGE_DIR="$(dirname "$SCRIPT_DIR")/package"
TEMPO_PACKAGE="tempo_2.8.0_linux_amd64.tar.gz"

echo "=== Tempo 安装开始 ==="

# 检查包文件是否存在
if [ ! -f "$PACKAGE_DIR/$TEMPO_PACKAGE" ]; then
    echo "错误: 找不到 Tempo 安装包 $PACKAGE_DIR/$TEMPO_PACKAGE"
    exit 1
fi

echo "找到 Tempo 安装包: $PACKAGE_DIR/$TEMPO_PACKAGE"

# 创建临时解压目录
TEMP_DIR="$TEMPO_DIR/temp_extract"
mkdir -p "$TEMP_DIR"

# 解压安装包
echo "正在解压 Tempo..."
tar -xzf "$PACKAGE_DIR/$TEMPO_PACKAGE" -C "$TEMP_DIR"

# 查看解压后的内容
echo "解压后的内容:"
ls -la "$TEMP_DIR"

# 查找 tempo 二进制文件
TEMPO_BINARY=""
if [ -f "$TEMP_DIR/tempo" ]; then
    # 二进制文件直接在根目录
    TEMPO_BINARY="$TEMP_DIR/tempo"
    echo "找到 Tempo 二进制文件: $TEMPO_BINARY"
else
    # 查找在子目录中的二进制文件
    TEMPO_BINARY=$(find "$TEMP_DIR" -name "tempo" -type f -executable | head -1)
    if [ -n "$TEMPO_BINARY" ]; then
        echo "找到 Tempo 二进制文件: $TEMPO_BINARY"
    else
        echo "错误: 无法找到 Tempo 二进制文件"
        echo "解压后的目录结构:"
        find "$TEMP_DIR" -type f -name "*tempo*" -o -name "*" | head -20
        rm -rf "$TEMP_DIR"
        exit 1
    fi
fi

# 创建bin目录
echo "创建bin目录..."
mkdir -p "$TEMPO_DIR/bin"

# 复制二进制文件到bin目录
echo "正在安装 Tempo 二进制文件到 bin 目录..."
cp "$TEMPO_BINARY" "$TEMPO_DIR/bin/"
chmod +x "$TEMPO_DIR/bin/tempo"

# 清理临时目录
rm -rf "$TEMP_DIR"

# 创建必要的目录
echo "创建数据目录..."
mkdir -p "$TEMPO_DIR/data/traces"
mkdir -p "$TEMPO_DIR/data/wal"
mkdir -p "$TEMPO_DIR/logs"

# 检查配置文件
if [ ! -f "$TEMPO_DIR/tempo.yaml" ]; then
    echo "警告: 配置文件 tempo.yaml 不存在"
else
    echo "配置文件已存在: tempo.yaml"
fi

echo "=== Tempo 安装完成 ==="
echo "二进制文件位置: $TEMPO_DIR/bin/tempo"
echo "配置文件位置: $TEMPO_DIR/tempo.yaml"
echo "数据目录: $TEMPO_DIR/data"
echo "日志目录: $TEMPO_DIR/logs"
echo ""
echo "使用 './service.sh' 启动 Tempo 服务"
