# NAT Reality Bridge

**$0.2 NAT VPS Extreme Optimization**  
**9929/CMI Entry + ISP Residential Exit Architecture**

NAT Reality Bridge is a practical open-source template for building a lightweight Xray Reality node on low-resource NAT VPS infrastructure.

NAT Reality Bridge 是一个面向低资源 NAT VPS 的 Xray Reality 部署模板，重点实践“入口/出口分离”架构：入口节点负责网络质量，出口节点负责 IP 质量。

> This repository contains only generic templates and documentation. It does not include production server addresses, passwords, private keys, UUIDs, or live node links.
>
> 本仓库只包含通用模板和文档，不包含真实服务器 IP、账号密码、私钥、UUID 或可用节点链接。

## 1. 项目简介

很多低价 NAT VPS 拥有不错的网络入口，例如 CN2、9929、CMI 或其他优化线路，但公网端口有限、内存很小，且本机 IP 信誉未必适合作为最终出口。本项目将 NAT VPS 作为轻量入口节点，再通过 SOCKS5 出站连接到 ISP 住宅出口，从而拆分网络质量和 IP 质量。

核心目标：

- 在极低内存环境中运行官方 Xray-core。
- 使用 VLESS Reality TCP Vision 作为入口协议。
- 使用 SOCKS5 outbound 接入 ISP Residential Exit。
- 保持部署简单、可审计、无 Docker、无数据库、无面板。

## 1. Introduction

NAT Reality Bridge is a deployment pattern for tiny NAT VPS nodes. The entry VPS handles route quality and connectivity, while an ISP SOCKS5 outbound handles IP reputation and residential egress.

The project focuses on a minimal, auditable Xray-core setup for constrained environments without Docker, databases, web panels, or heavyweight runtimes.

## 2. 架构说明 / Architecture

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

入口节点负责 NAT 映射、公网入口、Reality 握手和网络质量。出口节点由 SOCKS5 ISP 代理承担，负责最终公网出口 IP 和 IP 信誉。

The entry node handles NAT forwarding, public entry, Reality handshake, and route quality. The exit node is provided by a SOCKS5 ISP proxy and handles final egress IP reputation.

## 3. 为什么使用入口/出口分离

传统单 VPS 方案的问题：

- 网络线路好，不代表 IP 信誉好。
- IP 质量好，不代表到客户端网络路径好。
- 高质量网络加高质量 IP 往往成本高。
- 小 NAT VPS 无法承载复杂面板或多服务栈。

本项目的解决方式：

- 入口 NAT VPS 只负责稳定接入和低延迟路径。
- ISP SOCKS5 出口只负责最终 IP 质量。
- 两者可以独立替换、独立优化。
- Xray 配置保持极简，适合低内存节点。

Why separate entry and exit:

- A good route does not guarantee a good egress IP.
- A reputable IP does not guarantee good connectivity to the client.
- Combining both on one VPS is often expensive.
- Tiny NAT VPS instances cannot afford heavy control panels.

## 4. 技术特点 / Features

- NAT VPS support
- Low resource optimization
- Official Xray-core
- VLESS Reality
- TCP Vision, `xtls-rprx-vision`
- SOCKS5 outbound
- ISP residential exit architecture
- systemd-managed service
- No Docker
- No database
- No Node.js
- No web panel by default

## 5. 支持环境 / Supported Environment

- Debian 12 or Debian 13
- Linux x86_64
- Low RAM VPS
- NAT VPS with provider-side TCP port forwarding
- systemd available

The template was designed for very small servers. Always check memory, disk, architecture, NAT mapping, and firewall state before deploying.

## 6. 快速开始 / Quick Start

Do not run installation scripts blindly. Review placeholders and verify the VPS first.

不要直接执行危险命令。先检查 VPS 环境、NAT 端口和网络条件。

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

Provider NAT mapping:

```text
PUBLIC_ENDPOINT_PORT -> INTERNAL_XRAY_PORT
```

Reality profile used by this template:

```text
serverName: www.cloudflare.com
dest: www.cloudflare.com:443
spiderX: /
flow: xtls-rprx-vision
```

Install script:

```text
scripts/install.sh
```

The script is interactive and requires you to enter sensitive values at runtime. Review it before use.

## 7. 文档导航 / Documentation

- [Architecture](docs/architecture.md)
- [Deployment](docs/deployment.md)
- [Client URI](docs/client-uri.md)
- [Troubleshooting](docs/troubleshooting.md)

## 8. 安全说明 / Security Notes

Never commit:

- Reality `privateKey`
- Production UUID
- SSH credentials
- Proxy credentials
- Live VLESS node URI
- Personal server configuration
- Provider account information

不要提交：

- Reality 私钥
- 生产 UUID
- SSH 凭据
- 代理账号密码
- 真实节点链接
- 个人服务器配置
- 服务商账号信息

Before publishing a fork, run a full text scan for IP addresses, UUID-like strings, private keys, proxy credentials, and node URIs.

## License

MIT License. See [LICENSE](LICENSE).
