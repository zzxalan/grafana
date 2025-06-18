# 监控栈一体化部署方案

这是一个完整的监控、日志聚合和链路追踪解决方案，集成了 Grafana、Prometheus、Loki、Tempo、Node Exporter 和 MySQL Exporter。

## 🚀 功能特性

### 核心组件
- **Grafana 12.0.1** - 数据可视化和仪表盘平台
- **Prometheus 3.4.1** - 监控数据采集和存储
- **Loki 3.4.0** - 日志聚合系统
- **Tempo 2.8.0** - 分布式链路追踪
- **Node Exporter 1.9.1** - 系统指标采集
- **MySQL Exporter 0.17.2** - MySQL 数据库监控

### 主要特性
- 📊 **统一监控** - 系统、应用、数据库全方位监控
- 📈 **实时告警** - 基于 Prometheus 的智能告警规则
- 📋 **日志聚合** - 集中化日志收集和查询
- 🔍 **链路追踪** - 分布式系统调用链分析
- 🎛️ **可视化仪表盘** - 预配置的监控面板
- 🔧 **一键部署** - 自动化安装和配置脚本
- 🛠️ **统一管理** - 集中的服务启停和状态管理

## 📋 系统要求

- **操作系统**: Linux (推荐 Ubuntu 18.04+, CentOS 7+)
- **内存**: 最少 4GB，推荐 8GB+
- **磁盘空间**: 最少 20GB 可用空间
- **网络**: 互联网连接（用于下载安装包）
- **权限**: 具有 sudo 权限的用户账户

## 🛠️ 快速开始

### 1. 下载项目
```bash
git clone <repository-url>
cd grafana
```

### 2. 下载依赖包
使用 PowerShell 脚本下载所有必需的组件包：

```powershell
# Windows 环境
.\download-packages.ps1
```

或者手动下载到 `package` 目录：
- grafana-12.0.1.linux-amd64.tar.gz (~175MB)
- prometheus-3.4.1.linux-amd64.tar.gz (~112MB)
- node_exporter-1.9.1.linux-amd64.tar.gz (~11MB)
- mysqld_exporter-0.17.2.linux-amd64.tar.gz (~9MB)
- loki-linux-amd64.zip (~35MB)
- promtail-linux-amd64.zip (~30MB)
- tempo_2.8.0_linux_amd64.tar.gz (~57MB)

### 3. 安装所有组件
```bash
# 为脚本添加执行权限
chmod +x service.sh
chmod +x */install.sh
chmod +x */service.sh

# 安装所有组件
./prometheus/install.sh
./grafana/install.sh
./loki/install.sh
./node_exporter/install.sh
./mysqld_exporter/install.sh
./tempo/install.sh
```

### 4. 启动监控栈
```bash
# 启动所有服务
./service.sh start

# 查看服务状态
./service.sh status
```

## 📊 服务访问地址

启动成功后，可以通过以下地址访问各个服务：

| 服务 | 地址 | 用途 |
|------|------|------|
| Grafana | http://localhost:3000 | 数据可视化仪表盘 |
| Prometheus | http://localhost:9090 | 监控数据查询 |
| Loki | http://localhost:3100 | 日志查询 API |
| Tempo | http://localhost:3200 | 链路追踪查询 |
| Node Exporter | http://localhost:9100/metrics | 系统指标 |
| MySQL Exporter | http://localhost:9104/metrics | MySQL 指标 |

### Grafana 默认登录
- **用户名**: admin
- **密码**: admin（首次登录后需修改）

## 🎛️ 服务管理

### 统一服务管理
```bash
# 启动所有服务
./service.sh start

# 停止所有服务
./service.sh stop

# 重启所有服务
./service.sh restart

# 查看所有服务状态
./service.sh status

# 查看所有服务日志
./service.sh logs
```

### 单个服务管理
```bash
# 管理单个服务
./service.sh <服务名> <操作>

# 示例
./service.sh prometheus start
./service.sh grafana stop
./service.sh loki restart
./service.sh node_exporter status
```

支持的服务名：
- `prometheus` - Prometheus 监控服务
- `grafana` - Grafana 可视化服务
- `loki` - Loki 日志聚合服务
- `node_exporter` - Node Exporter 系统监控
- `mysqld_exporter` - MySQL Exporter 数据库监控
- `tempo` - Tempo 链路追踪服务

## 📈 监控配置

### Prometheus 监控目标
- Prometheus 自身监控 (localhost:9090)
- Node Exporter 系统监控 (localhost:9100)
- MySQL Exporter 数据库监控 (localhost:9104)
- Grafana 应用监控 (localhost:3000)
- Loki 日志服务监控 (localhost:3100)
- Tempo 追踪服务监控 (localhost:3200)

### 告警规则
内置告警规则包括：
- 服务可用性监控
- CPU 使用率告警 (>80%)
- 内存使用率告警 (>85%)
- 磁盘使用率告警 (>85%)
- 磁盘空间严重不足 (>95%)

### 数据源配置
Grafana 自动配置以下数据源：
- **Prometheus** - 监控指标数据源
- **Loki** - 日志数据源  
- **Tempo** - 链路追踪数据源

## 📋 仪表盘

项目包含预配置的 Grafana 仪表盘：
- **Node Exporter Dashboard** - 系统监控面板
- **MySQL Dashboard** - 数据库监控面板
- **Application Performance** - 应用性能监控
- **Log Analysis** - 日志分析面板

仪表盘文件位于 `grafana/dashboards/` 目录，会自动加载到 Grafana 中。

## 🔧 配置文件

### 主要配置文件
- `prometheus/prometheus.yml` - Prometheus 主配置
- `grafana/grafana.ini` - Grafana 主配置
- `loki/loki.yaml` - Loki 日志聚合配置
- `tempo/tempo.yaml` - Tempo 链路追踪配置
- `prometheus/rules/basic-alerts.yml` - 告警规则配置

### MySQL Exporter 配置
如需监控 MySQL，请编辑 `mysqld_exporter/my.cnf`：
```ini
[client]
user=exporter
password=your_password
host=localhost
port=3306
```

## 🚨 故障排查

### 常见问题
1. **端口冲突**: 确保所需端口未被占用
2. **权限问题**: 确保脚本有执行权限
3. **内存不足**: 监控栈需要足够的系统内存
4. **防火墙**: 确保相关端口可访问

### 查看日志
```bash
# 查看特定服务日志
./service.sh <服务名> logs

# 查看所有服务日志
./service.sh logs
```

### 端口检查
```bash
# 检查端口占用
./killport.sh <端口号>

# 查看所有相关端口
netstat -tlnp | grep -E "(3000|3100|3200|9090|9100|9104)"
```

## 🔒 安全配置

### 生产环境建议
1. **修改默认密码** - 更改 Grafana 默认管理员密码
2. **网络安全** - 配置防火墙规则，限制外部访问
3. **HTTPS** - 为 Web 界面启用 HTTPS
4. **认证授权** - 配置适当的用户认证和权限控制
5. **数据加密** - 启用数据传输和存储加密

### 网络配置
```bash
# 仅允许本地访问（默认配置）
# 如需外部访问，请修改各服务配置文件中的监听地址
```

## 📚 扩展功能

### 添加自定义监控目标
编辑 `prometheus/prometheus.yml`，添加新的 scrape_configs：
```yaml
scrape_configs:
  - job_name: 'my-app'
    static_configs:
      - targets: ['localhost:8080']
    scrape_interval: 15s
    metrics_path: /metrics
```

### 自定义告警规则
在 `prometheus/rules/` 目录添加新的告警规则文件：
```yaml
groups:
  - name: custom-alerts
    rules:
      - alert: CustomAlert
        expr: your_metric > threshold
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "自定义告警"
          description: "告警描述"
```

### 添加新仪表盘
将 JSON 格式的仪表盘文件放入 `grafana/dashboards/` 目录，重启 Grafana 后自动加载。

## 🤝 贡献指南

欢迎提交 Issue 和 Pull Request 来改进这个项目。

### 开发环境设置
1. Fork 这个仓库
2. 创建功能分支
3. 提交更改
4. 发起 Pull Request

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 📞 支持

如果遇到问题或需要帮助：
1. 查看故障排查部分
2. 提交 GitHub Issue
3. 查看各组件官方文档

---

**注意**: 这是一个用于学习和开发环境的监控栈配置。在生产环境使用前，请根据实际需求调整安全和性能配置。 