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

NAT Reality Bridge separates:

- Entry network quality
- Exit IP quality

Instead of searching for an expensive "perfect VPS", this architecture combines different resources and optimizes each part independently.

Starting from v1.1.0, this project provides:

- Interactive installer
- Two deployment modes
- Automatic VLESS URI generation
- Backup utilities
- Health check tools

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

# Design Philosophy

Traditional single-server deployments usually require one VPS to handle:

- Network routing
- Public exit IP
- Service deployment

This creates trade-offs:

- Good routes do not always mean good exit IP reputation.
- Good exit IPs do not always provide good client connectivity.
- Combining both requirements can become expensive.

NAT Reality Bridge separates responsibilities.

## Entry Node

Responsible for:

- NAT port forwarding
- Network path quality
- VLESS Reality entry
- Minimal Xray runtime environment

## Exit Node

Responsible for:

- ISP Residential IP
- IP reputation
- Final Internet egress

This allows the entry node to remain low-cost and lightweight while the exit identity can be replaced independently.

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
- SOCKS5 outbound support
- systemd management
- No Docker
- No database
- No Node.js
- No web panel by default

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
- Low-memory VPS
- NAT VPS with provider-side TCP port forwarding
- systemd available

This project targets resource-constrained servers.

Before deployment, check:

- Memory
- Disk space
- CPU architecture
- NAT mapping
- Firewall configuration

---

# Tested Environment (Not a Recommendation)

⚠️ This section only documents the author's test environment.

It is not:

- A provider recommendation
- A partnership
- A guarantee of availability or performance

Prices, inventory, routes, and IP reputation may change over time.

## Entry Node (NAT VPS)

Purpose:

Used as the Xray Reality entry node.

Test environment:

- Type: NAT VPS
- Region: Los Angeles, US
- Characteristics:
  - Low cost
  - Low resource usage
  - Optimized network route

Reference:

https://dash.fuckip.me

Note:

This environment is only a test case.

Users may choose any NAT VPS that meets their own requirements.

---

## Exit Node (ISP Residential SOCKS5)

Purpose:

Provides the final public egress IP.

Test environment:

- Type: Static ISP Residential SOCKS5
- Region: Los Angeles, US

Reference:

https://www.711proxy.com/signup?code=20560D

Selection reasons:

- Supports IP range inspection
- Easier region selection

Alternative:

Users may choose other ISP Residential Proxy providers.

---

# Quick Start

Clone the repository:

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

The v1.1.0 installer is interactive.

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
```

---

# Documentation

- [Architecture](docs/architecture.md)
- [Deployment](docs/deployment.md)
- [Client URI](docs/client-uri.md)
- [Troubleshooting](docs/troubleshooting.md)
- [Tested Environment](docs/providers.md)
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
