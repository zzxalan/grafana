#!/bin/bash

# Grafana 安装脚本
# 从 ../package 目录解压并安装 Grafana

set -e

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GRAFANA_DIR="$SCRIPT_DIR"
PACKAGE_DIR="$(dirname "$SCRIPT_DIR")/package"
GRAFANA_PACKAGE="grafana-12.0.1.linux-amd64.tar.gz"

echo "=== Grafana 安装开始 ==="

# 检查包文件是否存在
if [ ! -f "$PACKAGE_DIR/$GRAFANA_PACKAGE" ]; then
    echo "错误: 找不到 Grafana 安装包 $PACKAGE_DIR/$GRAFANA_PACKAGE"
    exit 1
fi

echo "找到 Grafana 安装包: $PACKAGE_DIR/$GRAFANA_PACKAGE"

# 创建临时解压目录
TEMP_DIR="$GRAFANA_DIR/temp_extract"
mkdir -p "$TEMP_DIR"

# 解压安装包
echo "正在解压 Grafana..."
tar -xzf "$PACKAGE_DIR/$GRAFANA_PACKAGE" -C "$TEMP_DIR"

# 查看解压后的内容
echo "解压后的内容:"
ls -la "$TEMP_DIR"

# 查找 grafana 安装目录
GRAFANA_EXTRACT_DIR=""
if [ -d "$TEMP_DIR/grafana-12.0.1" ]; then
    # 标准的解压目录结构
    GRAFANA_EXTRACT_DIR="$TEMP_DIR/grafana-12.0.1"
    echo "找到 Grafana 安装目录: $GRAFANA_EXTRACT_DIR"
else
    # 查找包含grafana的目录
    GRAFANA_EXTRACT_DIR=$(find "$TEMP_DIR" -name "*grafana*" -type d | head -1)
    if [ -n "$GRAFANA_EXTRACT_DIR" ]; then
        echo "找到 Grafana 安装目录: $GRAFANA_EXTRACT_DIR"
    else
        echo "错误: 无法找到 Grafana 安装目录"
        echo "解压后的目录结构:"
        find "$TEMP_DIR" -type d | head -20
        rm -rf "$TEMP_DIR"
        exit 1
    fi
fi

# 查找 grafana-server 二进制文件
GRAFANA_BINARY=""
if [ -f "$GRAFANA_EXTRACT_DIR/bin/grafana-server" ]; then
    GRAFANA_BINARY="$GRAFANA_EXTRACT_DIR/bin/grafana-server"
    echo "找到 Grafana 二进制文件: $GRAFANA_BINARY"
else
    echo "错误: 无法找到 Grafana 二进制文件"
    echo "查找 grafana-server:"
    find "$GRAFANA_EXTRACT_DIR" -name "*grafana*" -type f | head -10
    rm -rf "$TEMP_DIR"
    exit 1
fi

# 创建bin目录
echo "创建bin目录..."
mkdir -p "$GRAFANA_DIR/bin"

# 复制整个bin目录
echo "正在安装 Grafana 二进制文件到 bin 目录..."
cp -r "$GRAFANA_EXTRACT_DIR/bin/"* "$GRAFANA_DIR/bin/"
chmod +x "$GRAFANA_DIR/bin/"*

# 复制公共文件
echo "复制 Grafana 公共文件..."
if [ -d "$GRAFANA_EXTRACT_DIR/public" ]; then
    cp -r "$GRAFANA_EXTRACT_DIR/public" "$GRAFANA_DIR/"
fi

if [ -d "$GRAFANA_EXTRACT_DIR/conf" ]; then
    cp -r "$GRAFANA_EXTRACT_DIR/conf" "$GRAFANA_DIR/"
fi

# 清理临时目录
rm -rf "$TEMP_DIR"

# 创建必要的目录
echo "创建数据目录..."
mkdir -p "$GRAFANA_DIR/data"
mkdir -p "$GRAFANA_DIR/logs"
mkdir -p "$GRAFANA_DIR/plugins"
mkdir -p "$GRAFANA_DIR/conf/provisioning/dashboards"
mkdir -p "$GRAFANA_DIR/conf/provisioning/datasources"

# 创建仪表盘提供程序配置
echo "从示例文件复制配置..."
if [ -f "$GRAFANA_DIR/dashboards.yaml.example" ]; then
    cp "$GRAFANA_DIR/dashboards.yaml.example" "$GRAFANA_DIR/conf/provisioning/dashboards/dashboards.yaml"
    echo "已复制仪表盘配置从 dashboards.yaml.example"
else
    echo "警告: 找不到 dashboards.yaml.example，使用默认配置"
    cat > "$GRAFANA_DIR/conf/provisioning/dashboards/dashboards.yaml" << 'EOF'
apiVersion: 1

providers:
  - name: 'default'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    allowUiUpdates: true
    options:
      path: dashboards
EOF
fi

# 创建数据源配置
if [ -f "$GRAFANA_DIR/datasources.yaml.example" ]; then
    cp "$GRAFANA_DIR/datasources.yaml.example" "$GRAFANA_DIR/conf/provisioning/datasources/datasources.yaml"
    echo "已复制数据源配置从 datasources.yaml.example"
else
    echo "警告: 找不到 datasources.yaml.example，使用默认配置"
    cat > "$GRAFANA_DIR/conf/provisioning/datasources/datasources.yaml" << 'EOF'
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://localhost:9090
    isDefault: true
    editable: true
EOF
fi

# 检查配置文件
if [ ! -f "$GRAFANA_DIR/grafana.ini" ]; then
    echo "警告: 配置文件 grafana.ini 不存在"
else
    echo "配置文件已存在: grafana.ini"
fi

echo "=== Grafana 安装完成 ==="
echo "二进制文件位置: $GRAFANA_DIR/bin/grafana-server"
echo "配置文件位置: $GRAFANA_DIR/grafana.ini"
echo "数据目录: $GRAFANA_DIR/data"
echo "日志目录: $GRAFANA_DIR/logs"
echo "插件目录: $GRAFANA_DIR/plugins"
echo "仪表盘目录: $GRAFANA_DIR/dashboards"
echo "Provisioning配置: $GRAFANA_DIR/conf/provisioning"
echo ""
echo "仪表盘自动加载配置已启用，dashboards目录中的所有.json文件将自动加载"
echo "使用 './service.sh' 启动 Grafana 服务"
