# Node Exporter 模块

Node Exporter 是一个用于收集系统指标的 Prometheus exporter。

## 目录结构

```
node_exporter/
├── install.sh          # 安装脚本
├── start.sh            # 服务管理脚本
├── bin/                # 二进制文件目录 (安装后生成)
├── logs/               # 日志文件目录 (安装后生成)
└── README.md           # 说明文档
```

## 安装

运行安装脚本：

```bash
cd node_exporter
./install.sh
```

安装脚本会：
1. 从 `../package/` 目录解压 `node_exporter-1.9.1.linux-amd64.tar.gz`
2. 将二进制文件复制到 `bin/` 目录
3. 创建必要的目录结构

## 使用

### 启动服务

```bash
./start.sh start
```

### 停止服务

```bash
./start.sh stop
```

### 重启服务

```bash
./start.sh restart
```

### 查看状态

```bash
./start.sh status
```

### 查看日志

```bash
./start.sh logs
```

## 配置

- **监听端口**: 9100
- **日志文件**: `logs/node_exporter.log`
- **PID 文件**: `node_exporter.pid`

## 访问

服务启动后，可以通过以下 URL 访问：

- Metrics 接口: http://localhost:9100/metrics

## 注意事项

1. 确保端口 9100 未被其他程序占用
2. 如果需要修改监听端口，请编辑 `start.sh` 中的 `NODE_EXPORTER_PORT` 变量
3. 日志文件会记录服务的运行状态和错误信息 