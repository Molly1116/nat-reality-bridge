# NAT Reality Bridge

## 🚀 0.2美元 NAT VPS 极限优化方案：9929/CMI 三网优化入口 + ISP 家宽出口分离架构

**$0.2 NAT VPS Extreme Optimization**  
**9929/CMI Entry + ISP Residential Exit Architecture**

低资源 NAT VPS 环境下的 Xray Reality 部署架构实践。

> English users: [README.md](README.md)

NAT Reality Bridge 是一个开源部署模板，用于在低资源 NAT VPS 上构建轻量 Xray Reality 入口节点，并通过 SOCKS5 ISP 或家宽出口完成最终出站。

它不是售卖节点项目，不是商业机场，也不是一键翻墙产品。它是一个给自用基础设施参考的网络架构模板。

## 项目简介

本项目的核心思想是：

```text
入口节点负责线路质量。
出口节点负责 IP 质量。
```

低价 NAT VPS 如果线路不错，例如具备优化入口网络，就很适合作为入口节点。但 NAT VPS 自身 IP 未必适合作为最终出口。本项目将入口网络和出口 IP 解耦。

## 架构说明

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

NAT VPS 入口节点通过服务商端口映射接收客户端流量，并运行极简 Xray-core。SOCKS5 outbound 提供最终 ISP 或家宽出口 IP。

## 设计理念

传统单 VPS 方案通常让一台服务器同时承担：

- 网络线路
- 出口 IP
- 服务部署

这样很难兼顾，也容易成本过高。线路好的 VPS 不一定有好的出口 IP；IP 质量高的出口不一定有好的客户端接入线路。

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

这样入口节点可以保持低成本和小资源，出口身份也可以独立替换。

## 技术特点

- 支持 NAT VPS
- 低资源优化
- 官方 Xray-core
- VLESS Reality
- TCP Vision，`xtls-rprx-vision`
- SOCKS5 outbound
- ISP 家宽出口架构
- systemd 管理
- 不使用 Docker
- 不使用数据库
- 不使用 Node.js
- 默认不使用 Web 面板

## 支持环境

推荐基线：

- Debian 12 或 Debian 13
- Linux x86_64
- 小内存 VPS
- 支持服务商 TCP 端口映射的 NAT VPS
- systemd 可用

本模板面向资源受限服务器。部署前必须检查内存、磁盘、架构、NAT 映射和防火墙状态。

## 快速开始

克隆项目：

```bash
git clone https://github.com/Molly1116/nat-reality-bridge.git
cd nat-reality-bridge
```

执行前先审查脚本：

```bash
sed -n '1,220p' scripts/install.sh
```

不要盲目执行脚本。先检查 VPS 环境：

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

安装脚本为交互式。SOCKS5 凭据等敏感参数在运行时输入，不保存在本仓库中。

## 文档导航

- [架构说明](docs/architecture.md)
- [部署流程](docs/deployment.md)
- [客户端 URI](docs/client-uri.md)
- [排障记录](docs/troubleshooting.md)
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

发布 fork 前，请扫描 IP 地址、UUID 格式字符串、私钥、代理凭据和节点 URI。

## Roadmap

v1.0.0：

- 文档
- NAT VPS 架构模板
- Xray Reality 部署模板
- SOCKS5 outbound 模型

未来：

- 健康检查辅助脚本
- 备份恢复辅助脚本
- 更多验证自动化
- 更多服务商无关的排障记录

## License

MIT License. See [LICENSE](LICENSE).