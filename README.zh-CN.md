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

传统单 VPS 架构通常需要同时兼顾：

- 网络线路质量
- 出口 IP 质量
- 服务器成本

但三者往往难以同时满足。

因此，本项目将：

- 入口网络质量
- 出口 IP 质量

进行解耦。

不要寻找一台承担所有职责的服务器，而是通过架构拆分降低成本，提高部署灵活性。

入口节点：

- 负责网络路径和接入质量。

出口节点：

- 负责公网出口身份和 IP 质量。

从 v1.2.0 开始，本项目提供：

- 交互式安装器
- 两种部署模式
- 自动节点 URI 生成
- 备份脚本
- 健康检查工具
- 二维码生成
- 出口检测工具
- 面向新手的客户端文件
- 安装总结和安装日志

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
- 二维码扫码导入
- 出口 IP 检测工具
- 安装总结文件
- 卸载辅助脚本
- 安全更新提示脚本
- SOCKS5 outbound
- ISP Residential 出口架构
- systemd 管理
- 不使用 Docker
- 不使用数据库
- 不使用 Node.js
- 默认不使用 Web 面板

## 应用场景 / Use Cases

NAT Reality Bridge 可以用于构建低成本、可维护的跨区域网络基础设施，适合个人自用或实验环境。

常见应用场景包括：

- 访问国际开发资源、代码仓库和技术文档。
- 使用 ChatGPT、Claude 等国际 AI 服务。
- 构建需要稳定出口 IP 的个人网络环境。
- 进行低成本 VPS 网络架构实验。
- 学习和实践 Xray Reality、NAT VPS、入口/出口分离架构。

实际可用性取决于出口 IP 质量、目标服务策略以及用户所在网络环境。本项目不承诺一定可以访问任何具体服务。

## 测试环境参考 / Example Test Environment

本项目不推荐任何供应商。

以下环境仅用于作者实际测试、验证 NAT Reality Bridge 架构，并帮助用户复现部署流程。价格、库存、线路和服务质量可能随时间变化，请用户自行评估。

### NAT VPS Entry Node

用途：

作为 Xray Reality 入口节点。

测试环境：

- 类型：NAT VPS
- 地区：美国洛杉矶
- 特点：低成本、小内存、优化线路

参考链接：

https://dash.fuckip.me

说明：

该机器仅用于测试。用户也可以选择其他符合条件的 NAT VPS。

---

### ISP Residential Exit

用途：

提供最终公网出口 IP。

测试环境：

- 类型：Static ISP Residential SOCKS5
- 地区：美国洛杉矶

参考链接：

https://www.711proxy.com/signup?code=20560D

选择原因：

- 支持查看 IP 段
- 方便筛选地区

说明：

用户也可以选择其他 ISP Residential Proxy 服务。

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

该模式允许用户将入口节点与公网出口分离。通过独立出口节点，可以根据需求调整公网出口，而无需更换入口架构。

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
- 128MB RAM 或更高
- 推荐启用 swap
- 支持服务商 TCP 端口映射的 NAT VPS
- systemd 可用
- `curl` 或 `wget` 用于下载 Xray-core
- `unzip` 和 `sha256sum`

本模板面向资源受限服务器。

Minimal Debian NAT VPS 默认可能没有预装 Git。Git 不是 NAT Reality Bridge 的运行依赖，只是获取项目源码的一种方式。

64MB RAM NAT VPS 属于实验环境。Xray-core 本身资源占用较低，但 Debian 软件包安装阶段可能需要更多临时内存。在这类机器上，`apt install git` 可能因为 OOM 被系统终止。极低内存机器不建议使用 `git clone` 工作流。

v1.3.0 增加安装器资源模式：

- `EXTREME_LOW_RESOURCE`：低于 80MB RAM。跳过可选二维码依赖安装、ASN/Country 查询和非必要出口检测。
- `LOW_RESOURCE`：低于 160MB RAM。继续安装，并在缺少 swap 时提示。
- `NORMAL`：160MB RAM 或更高。

部署前必须检查：

- 内存
- 磁盘
- CPU 架构
- NAT 映射
- 防火墙状态

## 快速开始

本项目提供自动化部署工具，将复杂的 Xray Reality 配置流程简化为交互式安装流程。

安装器包括：

- 环境检测
- 配置生成
- Reality 参数生成
- 节点生成
- 二维码输出
- 出口检测

普通用户首次部署不应默认依赖 Git。未来版本可能提供更轻量的下载式安装路径，但当前文档不提供未经验证的一键安装命令。

执行任何来源的安装脚本前，请先确认：

- Debian 12/13、x86_64、systemd 可用。
- 内存尽量为 128MB 或更高。
- 小内存 NAT VPS 已启用或确认 swap。
- NAT 端口映射已经配置。
- 已审查安装脚本内容。
- 已确认存在 `curl` 或 `wget`。
- 已确认存在 `unzip` 和 `sha256sum`。

## Developer Workflow

当你需要阅读源码、修改脚本、二次开发或贡献项目时，使用 Git clone：

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

v1.2.0 安装脚本为交互式。

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
bash scripts/test-outbound.sh
```

## 安装完成说明

安装成功后，客户端文件会生成在：

```text
/root/nat-reality-bridge/
```

预计文件：

- `node.txt`：VLESS URI 和客户端参数。
- `node.png`：VLESS URI 二维码，安装 `qrencode` 后生成。
- `README.txt`：Android、Windows、iOS 客户端导入说明。
- `install-summary.txt`：安装结果、部署模式、Xray 状态、配置测试结果和安装时间。

安装完成示例：

```text
NAT Reality Bridge v1.2.0

Installation completed

Status:
[OK] Xray running
[OK] Configuration valid
[OK] Outbound test passed
```

## 文档导航

- [架构说明](docs/architecture.md)
- [部署流程](docs/deployment.md)
- [客户端 URI](docs/client-uri.md)
- [排障记录](docs/troubleshooting.md)
- [测试环境说明](docs/providers.md)
- [新手用户指南](docs/user-guide.md)
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

v1.2.0：

- 面向新手的安装完成界面
- 终端二维码和 PNG 二维码生成
- `/root/nat-reality-bridge/` 客户端文件目录
- 出口检测工具
- 安装总结和安装日志
- 卸载辅助脚本
- 不自动替换 Xray-core 的安全更新提示脚本
- 面向首次使用 VPS 用户的指南

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
