# NAT Reality Bridge

## 🚀 0.2美元 NAT VPS 极限优化方案：9929/CMI 三网优化入口 + ISP 家宽出口分离架构

**$0.2 NAT VPS Extreme Optimization**  
**9929/CMI Entry + ISP Residential Exit Architecture**

低资源 NAT VPS 环境下的 Xray Reality 部署架构实践。

> English users: [README.md](README.md)

NAT Reality Bridge 是一个轻量开源自动化部署工具，用于在低资源 NAT VPS 上构建极简 Xray Reality 入口节点，并可选通过 SOCKS5 ISP Residential（住宅）出口完成最终出站。

它不是售卖节点项目，不是商业机场，也不是代理订阅服务。它是一个面向自用基础设施的网络架构模板，用于参考和复现入口/出口分离方案。

## 项目简介

本项目的核心思想是：

```text
入口节点负责线路质量。
出口节点负责 IP 质量。
```

低价 NAT VPS 如果具备较好的入口网络，例如优化线路、较低延迟路径等，就很适合作为入口节点。

但 NAT VPS 自身 IP 未必适合作为最终出口。

因此，本项目将：

- 入口网络质量
- 出口 IP 质量

进行解耦。

不追求寻找一台同时拥有完美线路和优秀出口 IP 的 VPS，而是通过架构拆分降低成本，提高部署灵活性。

从 v1.1.0 开始，本项目提供：

- 交互式安装器
- 两种部署模式
- 自动节点 URI 生成
- 备份脚本
- 健康检查工具

## 部署架构

```text
Client
  |
  v
VLESS Reality TCP Vision
  |
  v
NAT VPS Entry Node
  |
  v
SOCKS5 Outbound
  |
  v
ISP Residential Exit
  |
  v
Internet
```

NAT VPS 入口节点通过服务商端口映射接收客户端流量，并运行极简 Xray-core。

在 ISP Residential Exit Mode 中，SOCKS5 outbound 提供最终 ISP Residential（住宅）出口 IP。

核心思想：

> 将入口线路质量和出口 IP 信誉分开优化。

## 设计理念

传统单 VPS 方案通常让一台服务器同时承担：

- 网络线路
- 出口 IP
- 服务部署

这样很难兼顾，也容易导致成本过高。

线路好的 VPS 不一定拥有优秀出口 IP；
出口 IP 质量高的服务器，也不一定具备良好的客户端接入线路。

NAT Reality Bridge 将角色拆开：

入口节点负责：

- NAT 映射
- 网络路径
- VLESS Reality 入口
- 极简 Xray 运行环境

出口节点负责：

- ISP Residential IP
- IP 信誉
- 最终互联网出口

这样入口节点可以保持低成本、小资源，出口身份也可以独立替换。

## 技术特点

- 支持 NAT VPS
- 低资源优化
- 官方 Xray-core
- VLESS Reality
- TCP Vision，`xtls-rprx-vision`
- 交互式安装器
- Basic Mode：VPS 原生出口
- ISP Residential Exit Mode：SOCKS5 住宅出口
- 自动生成 VLESS URI
- 健康检查和备份辅助脚本
- SOCKS5 outbound
- ISP Residential 出口架构
- systemd 管理
- 不使用 Docker
- 不使用数据库
- 不使用 Node.js
- 默认不使用 Web 面板

## 两种部署模式

### Basic Mode

Basic Mode 使用 VPS 原生出口。

优点：

- 除 VPS 本身成本外，不需要额外出口成本
- 部署最简单
- 不依赖额外代理

缺点：

- 出口 IP 质量取决于 VPS 服务商和 IP 段

### ISP Residential Exit Mode

ISP Residential Exit Mode 将 Xray 流量路由到带认证的 SOCKS5 ISP Residential（住宅）出口。

优点：

- 出口 IP 可控
- 出口可以独立替换
- 入口和出口职责分离

缺点：

- 需要额外代理成本
- 需要自行管理 SOCKS5 凭据

## 支持环境

推荐基线：

- Debian 12 或 Debian 13
- Linux x86_64
- 小内存 VPS
- 支持服务商 TCP 端口映射的 NAT VPS
- systemd 可用

本模板面向资源受限服务器。

部署前必须检查：

- 内存
- 磁盘
- CPU 架构
- NAT 映射
- 防火墙状态

## 实测环境（非推荐）

⚠️ 本项目不推荐任何供应商。

以下内容仅记录作者实际测试环境，用于帮助理解架构和复现部署。

供应商价格、库存、线路质量和 IP 状态可能随时间变化，请根据自身需求选择。

### 入口节点（NAT VPS）

用途：

作为 Xray Reality 入口节点。

测试环境：

- 类型：NAT VPS
- 地区：美国洛杉矶
- 特点：低成本、小内存、优化线路

测试环境参考链接：

https://dash.fuckip.me

说明：

该机器仅用于测试案例。

用户也可以选择其他符合条件的 NAT VPS。

### 出口节点（ISP Residential SOCKS5）

用途：

提供最终公网出口 IP。

测试环境：

- 类型：静态 ISP Residential SOCKS5
- 地区：美国洛杉矶

测试环境参考链接：

https://www.711proxy.com/signup?code=20560D

选择原因：

- 支持查看 IP 段
- 方便筛选地区

替代方案：

也可以选择其他 ISP Residential Proxy 服务，例如 Webshare 等。

## 快速开始

克隆项目：

```bash
git clone https://github.com/Molly1116/nat-reality-bridge.git
cd nat-reality-bridge
```

执行前建议先审查脚本：

```bash
sed -n '1,220p' scripts/install.sh
```

不要盲目执行脚本。

先检查 VPS 环境：

```bash
date -Is
uname -a
cat /etc/os-release
ip -br addr
ip route show
ss -tnlp
free -h
df -hT
systemd-detect-virt -v || true
```

确认脚本内容和 NAT 端口映射后再执行：

```bash
bash scripts/install.sh
```

v1.1.0 安装脚本为交互式。

它会先检查：

- root 权限
- Debian 版本
- CPU 架构
- systemd
- 内存
- 磁盘空间

随后让用户选择：

- Basic Mode
- ISP Residential Exit Mode

SOCKS5 凭据等敏感参数只在运行时输入，不保存在本仓库中。

辅助工具：

```bash
bash scripts/health-check.sh
bash scripts/backup.sh
```

## 文档导航

- [架构说明](docs/architecture.md)
- [部署流程](docs/deployment.md)
- [客户端 URI](docs/client-uri.md)
- [排障记录](docs/troubleshooting.md)
- [测试环境说明](docs/providers.md)
- [English README](README.md)

## 安全说明

不要提交：

- Reality `privateKey`
- 生产 UUID
- SSH 凭据
- 代理账号密码
- 真实 VLESS 节点链接
- 个人服务器配置
- 服务商账号信息

发布 fork 前，请扫描：

- IP 地址
- UUID 格式字符串
- 私钥
- 代理凭据
- 节点 URI

## Roadmap

v1.1.0：

- 交互式安装器
- Basic deployment mode
- ISP Residential Exit mode
- 自动生成 VLESS URI
- 健康检查工具
- 测试环境说明文档

v1.0.0：

- 文档
- NAT VPS 架构模板
- Xray Reality 部署模板
- SOCKS5 outbound 模型

未来：

- 自动化诊断增强
- 备份恢复增强
- 更多验证自动化
- 更多服务商无关的排障记录
- 更多 Linux 环境支持

## License

MIT License. See [LICENSE](LICENSE).
