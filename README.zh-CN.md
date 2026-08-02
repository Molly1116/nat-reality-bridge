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

### 轻量部署

- 支持 NAT VPS 和服务商 TCP 端口映射环境。
- 针对 64MB/128MB RAM 级别小内存 VPS 优化。
- 使用官方 Xray-core，并通过已验证的 systemd 或已有 Supervisor 管理。
- 不依赖 Docker、数据库、Node.js 或 Web 面板。

### 网络架构

- VLESS Reality TCP Vision，使用 `xtls-rprx-vision`。
- Basic Mode 使用 VPS 原生出口。
- ISP Residential Exit Mode 通过 SOCKS5 outbound 出口。
- 入口线路质量和出口 IP 质量可以独立替换。

### 管理能力

- 交互式安装器，包含环境检查和配置验证。
- 自动生成 VLESS URI，可选二维码输出。
- 完整仓库用户可使用备份、健康检查、出口检测、更新提示和卸载辅助脚本。
- 生成安装总结和安装日志，方便排障。

### 可靠部署与恢复

- 只有确认 PID 1 和 system bus 都可用后才使用 systemd。
- 在受限 NAT 容器中可使用已经运行的 Supervisor；安装器绝不自动安装 Supervisor。
- 没有可靠服务管理器时，会在激活配置前安全退出。
- 使用 Xray 二进制原子替换，并记录不含敏感信息的安装状态。
- 检测到高级 Xray 配置时会停止，避免误覆盖。
- 临时配置文件以 `.json` 结尾，确保 Xray 能在激活前正确识别 JSON 格式。

## 应用场景 / Use Cases

NAT Reality Bridge 可以用于构建低成本、可维护的跨区域网络基础设施，适合个人自用或实验环境。

常见应用场景包括：

- 访问国际开发资源、代码仓库和技术文档。
- 使用 ChatGPT、Claude 等国际 AI 服务。
- 构建需要稳定出口 IP 的个人网络环境。
- 进行低成本 VPS 网络架构实验。
- 学习和实践 Xray Reality、NAT VPS、入口/出口分离架构。

实际可用性取决于出口 IP 质量、目标服务策略以及用户所在网络环境。本项目不承诺一定可以访问任何具体服务。

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
- 可用的 systemd service bus，或已有且可工作的 Supervisor
- `curl` 或 `wget` 用于下载 Xray-core
- `unzip` 和 `sha256sum`

本模板面向资源受限服务器。

Minimal Debian NAT VPS 默认可能没有预装 Git。Git 不是 NAT Reality Bridge 的运行依赖，只是获取项目源码的一种方式。

64MB RAM NAT VPS 属于实验环境。Xray-core 本身资源占用较低，但极简容器仍可能在下载、解压或软件包操作阶段失败。安装器不会自动安装额外软件；缺少必要工具或可靠服务管理器时会安全停止。建议最低使用 128MB RAM 并启用 swap。

安装器不会自动安装 Supervisor、Docker、Git、Python、Node.js 或数据库。服务商必须至少提供一个映射到内部 Xray 监听端口的公网 TCP NAT 端口，通常为 `443`。

v1.3.0 增加安装器资源模式：

- `EXTREME_LOW_RESOURCE`：低于 80MB RAM。跳过二维码生成、ASN/Country 查询和非必要出口检测。
- `LOW_RESOURCE`：低于 160MB RAM。继续安装，并在缺少 swap 时提示。
- `NORMAL`：160MB RAM 或更高。

## 安装恢复

如果 SSH 会话断开或安装被中断，不要立刻重新安装。先查看安装状态。

单文件下载：

```bash
bash install.sh --status
```

完整仓库目录：

```bash
bash scripts/install.sh --status
```

如显示未完成事务，先检查现有配置和二进制状态。推荐的恢复命令会**重新启动一轮受保护安装事务**，不会从具体阶段继续，并且可能生成新的节点参数。

单文件下载：

```bash
bash install.sh --restart-interrupted
```

完整仓库目录：

```bash
bash scripts/install.sh --restart-interrupted
```

兼容别名：

```bash
# 单文件下载
bash install.sh --resume

# 完整仓库目录
bash scripts/install.sh --resume
```

`--resume` 只是 `--restart-interrupted` 的兼容别名，不是真正的阶段断点续跑。新事务可能生成新的节点参数，应以最后一次成功安装生成的节点信息为准。

root-only 的 install-state 只记录阶段、时间、服务后端、备份路径、状态和非敏感失败原因摘要，不保存 UUID、Reality privateKey、SOCKS5 password 或 VLESS URI。

### 配置测试失败

配置校验是硬性门槛：通过前不会激活 Xray、不会创建 managed marker，也不能视为节点已部署。校验失败时，请先使用 `bash install.sh --status` 查看 `status=FAILED` 和非敏感失败原因，再查看 `/var/log/nat-reality-bridge-install.log`。安装器会恢复本次事务之前的状态，并删除本次临时配置、未激活的 `xray.new.*` 二进制和新生成的客户端输出文件。不要编辑临时配置绕过校验；请下载当前安装器，审查失败原因后再启动新的受保护安装事务。

## 受管安装归属

安装成功后，NAT Reality Bridge 会在 `/etc/nat-reality-bridge/managed.marker` 写入仅 root 可读的非敏感归属标记。它只包含项目名称、标记格式、安装版本和时间，以及随机 install ID。

安装器、更新脚本和卸载脚本只有在标记合法时，才会把已有 Xray 配置视为本工具受管。没有该标记的旧部署会被保留，需要人工审查；不会被自动迁移、覆盖或删除。

## 验证语义

`scripts/test-outbound.sh` 可以验证 ISP SOCKS5 地址是否接受提供的凭据。这只是 **Direct SOCKS5 Test**，不代表 VLESS Reality 节点已成功。

**Through Xray Verification** 需要经过认证的 Reality 流量和真实客户端测试。请从外部客户端确认公网 NAT 入口；同机 NAT hairpin 测试可能造成误判。

部署前必须检查：

- 内存
- 磁盘
- CPU 架构
- NAT 映射
- 防火墙状态

## 快速开始

第一次部署用户请从这里开始：

**[完整部署教程](docs/full-deployment-guide.zh-CN.md)**

NAT Reality Bridge 提供交互式安装器，用于环境检查、Xray Reality 配置生成、节点 URI 输出和出口测试。

如果你已经了解部署流程，可以使用 `curl` 下载单文件安装器：

```bash
curl -fsSL https://raw.githubusercontent.com/Molly1116/nat-reality-bridge/main/scripts/install.sh -o install.sh
sed -n '1,220p' install.sh
sed -n '221,520p' install.sh
sed -n '521,1120p' install.sh
bash install.sh
```

或使用 `wget`：

```bash
wget https://raw.githubusercontent.com/Molly1116/nat-reality-bridge/main/scripts/install.sh -O install.sh
sed -n '1,220p' install.sh
bash install.sh
```

普通用户安装不需要 Git。如果 VPS 上既没有 `curl` 也没有 `wget`，可以在其他机器下载 GitHub 仓库 ZIP，解压后上传到 VPS，再执行 `bash scripts/install.sh`。

## Developer Workflow

当你需要阅读源码、修改脚本、二次开发或贡献项目时，使用 Git clone：

```bash
git clone https://github.com/Molly1116/nat-reality-bridge.git
cd nat-reality-bridge
```

执行前建议先审查脚本：

```bash
sed -n '1,220p' scripts/install.sh
sed -n '221,520p' scripts/install.sh
sed -n '521,1120p' scripts/install.sh
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

完整仓库用户还可以使用辅助脚本：

```bash
bash scripts/health-check.sh
bash scripts/backup.sh
bash scripts/test-outbound.sh
bash scripts/update.sh
bash scripts/uninstall.sh
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

`node.txt` 是键值格式文件。导入时只复制 `VLESS_URI=` 后面的值，不要复制变量名。远程服务器上的 `node.png` 需要先下载到本机或手机后再扫码。

安装完成示例：

```text
NAT Reality Bridge v1.5.1

Installation completed

Status:
[OK] Xray running
[OK] Configuration valid
[OK] Outbound test passed
```

只有同时满足以下条件，才算安装完成：

1. Xray 配置测试通过。
2. 选定后端报告 Xray active 或 Supervisor RUNNING。
3. `/etc/nat-reality-bridge/managed.marker` 已生成。
4. 客户端节点文件已生成。
5. 内部 Reality 监听端口存在。
6. ISP Mode 下 Direct SOCKS5 Test 通过。
7. 外部客户端已完成 Reality 连接。
8. Reality 流量使用预期的原生或 ISP 出口路径。
9. 服务重启后仍保持可用。

Xray 下载成功不代表部署成功。服务已启动和 Direct SOCKS5 Test 通过，也不能代替外部 Reality 验证。

## 文档导航

- [完整部署教程](docs/full-deployment-guide.zh-CN.md)
- [Complete Deployment Guide](docs/full-deployment-guide.md)
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

## License

MIT License. See [LICENSE](LICENSE).
