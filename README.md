# NAT Reality Bridge

## 🚀 0.2美元 NAT VPS 极限优化方案：9929/CMI 三网优化入口 + ISP 家宽出口分离架构

**$0.2 NAT VPS Extreme Optimization**  
**9929/CMI Entry + ISP Residential Exit Architecture**

Low-resource Xray Reality deployment pattern for NAT VPS environments.

> 中文用户请阅读：[README.zh-CN.md](README.zh-CN.md)

NAT Reality Bridge is an open-source deployment template for building a lightweight Xray Reality entry node on NAT VPS infrastructure, then routing traffic through a SOCKS5 ISP or residential exit.

It is not a node-selling project, not a commercial proxy service, and not a turnkey bypass product. It is a reusable network architecture template for self-managed infrastructure.

## Overview

This project focuses on one core idea:

```text
Entry node handles route quality.
Exit node handles IP quality.
```

A low-cost NAT VPS can be valuable as an entry node when it has good network routes, such as optimized regional connectivity. However, the entry VPS IP itself may not be suitable as the final egress IP. NAT Reality Bridge separates these two concerns.

## Architecture

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

The NAT VPS entry node receives client traffic through provider-side port forwarding and runs a minimal Xray-core service. The SOCKS5 outbound provides the final ISP or residential egress IP.

## Design Philosophy

A traditional single-VPS design asks one server to handle everything:

- Network route quality
- Public egress IP reputation
- Service deployment

That is difficult to optimize and often expensive. A VPS with good routes may have a poor egress IP. A high-quality residential or ISP IP may not provide a good route to the client.

NAT Reality Bridge separates the roles:

Entry node responsibilities:

- NAT port forwarding
- Network path quality
- VLESS Reality entry
- Minimal Xray runtime

Exit node responsibilities:

- ISP residential IP
- IP reputation
- Final Internet egress

This keeps the entry node cheap and small while allowing the exit identity to be replaced independently.

## Features

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

## Supported Environment

Recommended baseline:

- Debian 12 or Debian 13
- Linux x86_64
- Low RAM VPS
- NAT VPS with provider-side TCP port forwarding
- systemd available

The template is designed for constrained servers. Always check memory, disk, architecture, NAT mapping, and firewall state before deployment.

## Quick Start

Clone the project:

```bash
git clone https://github.com/Molly1116/nat-reality-bridge.git
cd nat-reality-bridge
```

Review the installer before running it:

```bash
sed -n '1,220p' scripts/install.sh
```

Do not execute scripts blindly. First check the VPS environment:

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

Run only after reviewing the script and preparing NAT port forwarding:

```bash
bash scripts/install.sh
```

The installer is interactive. Sensitive values such as SOCKS5 credentials are entered at runtime and are not stored in this repository.

## Documentation

- [Architecture](docs/architecture.md)
- [Deployment](docs/deployment.md)
- [Client URI](docs/client-uri.md)
- [Troubleshooting](docs/troubleshooting.md)
- [中文 README](README.zh-CN.md)

## Security Notes

Never commit:

- Reality `privateKey`
- Production UUID
- SSH credentials
- Proxy credentials
- Live VLESS node URI
- Personal server configuration
- Provider account information

Before publishing a fork, scan for IP addresses, UUID-like strings, private keys, proxy credentials, and node URIs.

## Roadmap

v1.0.0:

- Documentation
- NAT VPS architecture template
- Xray Reality deployment template
- SOCKS5 outbound model

Future:

- Health check helper
- Backup restore helper
- More automation around validation
- More provider-neutral troubleshooting notes

## License

MIT License. See [LICENSE](LICENSE).