# NAT Reality Bridge

## 🚀 $0.2 NAT VPS Extreme Optimization: 9929/CMI Entry + ISP Residential Exit Architecture

**0.2美元 NAT VPS 极限优化方案：9929/CMI 三网优化入口 + ISP住宅出口分离架构**

A lightweight Xray Reality deployment architecture for low-resource NAT VPS environments.

> 中文用户请查看：[README.zh-CN.md](README.zh-CN.md)

---

NAT Reality Bridge is a lightweight open-source automation tool for building minimal Xray Reality entry nodes on low-resource NAT VPS infrastructure, with optional SOCKS5 ISP Residential exit support.

This project is not a node-selling service, proxy subscription service, or hosted solution.

It is a reusable infrastructure template for personal deployments and network architecture experiments.

---

# Overview

The core idea:

```text
Entry node optimizes connectivity.
Exit node optimizes IP reputation.
```

Low-cost NAT VPS instances can provide excellent network paths, such as optimized routes, low latency, or premium upstream connectivity.

However, the VPS public IP may not always be suitable as the final Internet exit.

Traditional single-VPS deployments often try to satisfy three requirements at the same time:

- Network route quality
- Exit IP quality
- Server cost

In practice, these three goals are difficult to optimize on one machine.

NAT Reality Bridge separates:

- Entry network quality
- Exit IP quality

Instead of searching for one server that carries every responsibility, this architecture splits the system into two roles.

Entry node:

- Handles network path and client access quality.

Exit node:

- Handles public egress identity and IP quality.

The result is a low-cost, maintainable cross-region network infrastructure pattern that can be adjusted without rebuilding every layer at once.

Starting from v1.2.0, this project provides:

- Interactive installer
- Two deployment modes
- Automatic VLESS URI generation
- Backup utilities
- Health check tools
- QR code generation
- Outbound test helper
- Beginner-friendly client files
- Install summary and install log

---

# Architecture

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

The NAT VPS entry node receives client traffic through provider-side port forwarding and runs a minimal Xray-core instance.

In ISP Residential Exit Mode, SOCKS5 outbound provides the final ISP Residential egress IP.

Core concept:

> Separate network connectivity optimization from exit IP reputation optimization.

---

# Features

- NAT VPS support
- Low-resource optimization
- Official Xray-core
- VLESS Reality
- TCP Vision (`xtls-rprx-vision`)
- Interactive installer
- Basic Mode: VPS native exit
- ISP Residential Exit Mode: SOCKS5 residential exit
- Automatic VLESS URI generation
- Health check utilities
- Backup utilities
- QR code generation for client import
- Outbound IP test utility
- Install summary file
- Uninstall helper
- Update safety helper
- SOCKS5 outbound support
- systemd management
- No Docker
- No database
- No Node.js
- No web panel by default

---

# 应用场景 / Use Cases

NAT Reality Bridge can be used to build low-cost and maintainable cross-region network infrastructure for personal or lab environments.

Common use cases include:

- Accessing international developer resources, code repositories, and technical documentation.
- Using international AI services such as ChatGPT, Claude, and similar tools.
- Building a personal network environment that benefits from a stable egress IP.
- Experimenting with low-cost VPS network architecture.
- Learning and practicing Xray Reality, NAT VPS, and entry/exit separation design.

Actual availability depends on egress IP quality, target service policies, and the user's local network environment. This project does not guarantee access to any specific service.

---

# 测试环境参考 / Example Test Environment

This project does not recommend any provider.

The following environments are only used by the author to test NAT Reality Bridge, validate the architecture, and help users reproduce the deployment flow. Pricing, inventory, routes, and service quality may change over time. Please evaluate providers independently.

## NAT VPS Entry Node

Purpose:

Used as the Xray Reality entry node.

Test environment:

- Type: NAT VPS
- Region: Los Angeles, US
- Characteristics: low cost, low memory, optimized route

Reference:

https://dash.fuckip.me

Note:

This machine is only used for testing. Users may choose any other NAT VPS that meets their own requirements.

---

## ISP Residential Exit

Purpose:

Provides the final public egress IP.

Test environment:

- Type: Static ISP Residential SOCKS5
- Region: Los Angeles, US

Reference:

https://www.711proxy.com/signup?code=20560D

Selection reasons:

- Supports IP range inspection
- Makes region filtering easier

Note:

Users may choose other ISP Residential Proxy services.

---

# Deployment Modes

## Basic Mode

Basic Mode uses the VPS native public exit.

### Advantages

- No additional proxy cost
- Simplest deployment
- Suitable for testing and personal use

### Limitations

- Exit IP quality depends on the VPS provider and IP range

---

## ISP Residential Exit Mode

ISP Residential Exit Mode routes Xray traffic through an authenticated SOCKS5 ISP Residential proxy.

This mode separates the entry node from the public egress. The public exit can be adjusted or replaced according to network requirements without changing the entry architecture.

### Advantages

- Controllable exit IP
- Replaceable exit identity
- Separate entry and exit optimization

### Limitations

- Requires additional proxy cost
- Requires managing SOCKS5 credentials

---

# Supported Environment

Recommended baseline:

- Debian 12 or Debian 13
- Linux x86_64
- 128 MB RAM or above
- Swap recommended
- NAT VPS with provider-side TCP port forwarding
- systemd available

This project targets resource-constrained servers.

Minimal Debian NAT VPS images may not include Git. Git is not a runtime dependency of NAT Reality Bridge; it is only one way to fetch the project source code.

64 MB RAM NAT VPS instances should be treated as experimental environments. Xray-core itself is lightweight, but Debian package installation can require more temporary memory. In this class of machine, `apt install git` may be terminated by the system because of OOM. Avoid the Git clone workflow on extremely low-memory nodes.

Before deployment, check:

- Memory
- Disk space
- CPU architecture
- NAT mapping
- Firewall configuration

---

# Quick Start

NAT Reality Bridge provides an automation tool that turns the Xray Reality deployment process into an interactive installer.

The installer covers:

- Environment detection
- Config generation
- Reality parameter generation
- Node URI generation
- QR code output
- Outbound testing

For normal users, the first deployment path should not assume Git is already installed. Future versions may provide a lighter download-based installation path, but this repository does not document an unverified one-command installer yet.

Use the checklist below before running the installer from any source:

- Confirm Debian 12/13, x86_64, and systemd.
- Confirm memory is 128 MB or above when possible.
- Enable or confirm swap on very small NAT VPS nodes.
- Confirm NAT port mapping before starting Xray.
- Review the install script before execution.

## Developer Workflow

Use Git clone when you want to read source code, modify scripts, build your own fork, or contribute to the project:

```bash
git clone https://github.com/Molly1116/nat-reality-bridge.git
cd nat-reality-bridge
```

Review the installer before execution:

```bash
sed -n '1,220p' scripts/install.sh
```

Check your VPS environment:

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

After verifying the script and NAT port mapping:

```bash
bash scripts/install.sh
```

The v1.2.0 installer is interactive.

It will check:

- Root privileges
- Debian version
- CPU architecture
- systemd availability
- Memory
- Disk space

Then it allows users to choose:

- Basic Mode
- ISP Residential Exit Mode

Sensitive values such as SOCKS5 credentials are entered at runtime and are not stored in this repository.

Additional tools:

```bash
bash scripts/health-check.sh
bash scripts/backup.sh
bash scripts/test-outbound.sh
```

# Installation Output / 安装完成说明

After a successful install, client files are generated under:

```text
/root/nat-reality-bridge/
```

Expected files:

- `node.txt`: VLESS URI and client parameters.
- `node.png`: QR code for the VLESS URI, when `qrencode` is available.
- `README.txt`: client import notes for Android, Windows, and iOS.
- `install-summary.txt`: install result, mode, Xray status, config test result, and install time.

Example completion output:

```text
NAT Reality Bridge v1.2.0

Installation completed

Status:
[OK] Xray running
[OK] Configuration valid
[OK] Outbound test passed
```

---

# Documentation

- [Architecture](docs/architecture.md)
- [Deployment](docs/deployment.md)
- [Client URI](docs/client-uri.md)
- [Troubleshooting](docs/troubleshooting.md)
- [Tested Environment](docs/providers.md)
- [User Guide](docs/user-guide.md)
- [中文文档](README.zh-CN.md)

---

# Security

Never commit:

- Reality `privateKey`
- Production UUID
- SSH credentials
- Proxy credentials
- Real VLESS node links
- Personal server configuration
- Provider account information

Before publishing a fork, scan for:

- IP addresses
- UUID-like strings
- Private keys
- Proxy credentials
- Node URIs

---

# Roadmap

## v1.2.0

- Beginner-friendly installation completion screen
- Terminal and PNG QR code generation
- Client file directory under `/root/nat-reality-bridge/`
- Outbound test helper
- Install summary and install log
- Uninstall helper
- Safe update helper without automatic Xray-core replacement
- User guide for first-time VPS users

## v1.1.0

- Interactive installer
- Basic deployment mode
- ISP Residential Exit mode
- Automatic VLESS URI generation
- Health check tools
- Tested environment documentation

## v1.0.0

- Documentation
- NAT VPS architecture template
- Xray Reality deployment template
- SOCKS5 outbound model

## Future

- Enhanced automated diagnostics
- Improved backup and recovery
- More deployment validation
- More provider-independent troubleshooting records
- More Linux distribution support

---

# License

MIT License. See [LICENSE](LICENSE).
