#!/bin/bash

# MySQL Exporter 安装脚本
# 从 ../package 目录解压并安装 MySQL Exporter

set -e

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MYSQLD_EXPORTER_DIR="$SCRIPT_DIR"
PACKAGE_DIR="$(dirname "$SCRIPT_DIR")/package"
MYSQLD_EXPORTER_PACKAGE="mysqld_exporter-0.17.2.linux-amd64.tar.gz"

echo "=== MySQL Exporter 安装开始 ==="

# 检查包文件是否存在
if [ ! -f "$PACKAGE_DIR/$MYSQLD_EXPORTER_PACKAGE" ]; then
    echo "错误: 找不到 MySQL Exporter 安装包 $PACKAGE_DIR/$MYSQLD_EXPORTER_PACKAGE"
    exit 1
fi

echo "找到 MySQL Exporter 安装包: $PACKAGE_DIR/$MYSQLD_EXPORTER_PACKAGE"

# 创建临时解压目录
TEMP_DIR="$MYSQLD_EXPORTER_DIR/temp_extract"
mkdir -p "$TEMP_DIR"

# 解压安装包
echo "正在解压 MySQL Exporter..."
tar -xzf "$PACKAGE_DIR/$MYSQLD_EXPORTER_PACKAGE" -C "$TEMP_DIR"

# 查看解压后的内容
echo "解压后的内容:"
ls -la "$TEMP_DIR"

# 查找 mysqld_exporter 二进制文件
MYSQLD_EXPORTER_BINARY=""
if [ -f "$TEMP_DIR/mysqld_exporter" ]; then
    # 二进制文件直接在根目录
    MYSQLD_EXPORTER_BINARY="$TEMP_DIR/mysqld_exporter"
    echo "找到 MySQL Exporter 二进制文件: $MYSQLD_EXPORTER_BINARY"
else
    # 查找在子目录中的二进制文件
    MYSQLD_EXPORTER_BINARY=$(find "$TEMP_DIR" -name "mysqld_exporter" -type f -executable | head -1)
    if [ -n "$MYSQLD_EXPORTER_BINARY" ]; then
        echo "找到 MySQL Exporter 二进制文件: $MYSQLD_EXPORTER_BINARY"
    else
        echo "错误: 无法找到 MySQL Exporter 二进制文件"
        echo "解压后的目录结构:"
        find "$TEMP_DIR" -type f -name "*mysqld_exporter*" -o -name "*" | head -20
        rm -rf "$TEMP_DIR"
        exit 1
    fi
fi

# 创建bin目录
echo "创建bin目录..."
mkdir -p "$MYSQLD_EXPORTER_DIR/bin"

# 复制二进制文件到bin目录
echo "正在安装 MySQL Exporter 二进制文件到 bin 目录..."
cp "$MYSQLD_EXPORTER_BINARY" "$MYSQLD_EXPORTER_DIR/bin/"
chmod +x "$MYSQLD_EXPORTER_DIR/bin/mysqld_exporter"

# 清理临时目录
rm -rf "$TEMP_DIR"

# 创建必要的目录
echo "创建日志目录..."
mkdir -p "$MYSQLD_EXPORTER_DIR/logs"

echo "=== MySQL Exporter 安装完成 ==="
echo "二进制文件位置: $MYSQLD_EXPORTER_DIR/bin/mysqld_exporter"
echo "日志目录: $MYSQLD_EXPORTER_DIR/logs"
echo ""
echo "请编辑配置文件 my.cnf 设置正确的数据库连接信息"
echo "然后使用 './service.sh' 启动 MySQL Exporter 服务" 