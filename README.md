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

### Lightweight Deployment

- Supports NAT VPS environments and provider-side TCP port forwarding.
- Optimized for 64 MB and 128 MB RAM class VPS nodes.
- Uses official Xray-core with verified systemd management or an existing Supervisor fallback.
- Does not require Docker, a database, Node.js, or a web panel.

### Network Architecture

- VLESS Reality TCP Vision with `xtls-rprx-vision`.
- Basic Mode exits through the VPS native network.
- ISP Residential Exit Mode routes traffic through authenticated SOCKS5 outbound.
- Keeps entry network quality and exit IP quality independently replaceable.

### Management

- Interactive installer with environment checks and config validation.
- Automatic VLESS URI generation and optional QR code output.
- Backup, health-check, outbound-test, update, and uninstall helper scripts for full repository users.
- Install summary and install log for troubleshooting.

### Reliable Deployment And Recovery

- Uses systemd only after confirming that PID 1 and the system bus are usable.
- Falls back to an already-running Supervisor instance in restricted NAT containers; it never installs Supervisor automatically.
- Stops safely before activation when no reliable service manager is available.
- Uses an atomic Xray binary replacement path and records non-secret installation state for recovery.
- Protects existing advanced Xray configurations from accidental overwrite.
- Tests a temporary configuration whose filename ends in `.json`, so Xray can identify its JSON format before activation.

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
- a usable systemd service bus, or an existing working Supervisor instance
- `curl` or `wget` for downloading Xray-core
- `unzip` and `sha256sum`

This project targets resource-constrained servers.

Minimal Debian NAT VPS images may not include Git. Git is not a runtime dependency of NAT Reality Bridge; it is only one way to fetch the project source code.

64 MB RAM NAT VPS instances should be treated as experimental environments. Xray-core itself is lightweight, but minimal containers can still fail during download, extraction, or package work. The installer never installs extra software automatically; an extreme container can therefore stop safely when required tools or a reliable service manager are absent. Use 128 MB RAM or above, with swap enabled, as the recommended minimum.

The installer does not install Supervisor, Docker, Git, Python, Node.js, or a database. A provider must expose at least one public TCP NAT port mapped to the internal Xray listener, normally `443`.

v1.3.0 adds installer resource modes:

- `EXTREME_LOW_RESOURCE`: below 80 MB RAM. Skips QR code generation, ASN/Country lookup, and non-essential outbound checks.
- `LOW_RESOURCE`: below 160 MB RAM. Continues installation and warns when swap is missing.
- `NORMAL`: 160 MB RAM or above.

## Installation Recovery

If an SSH session closes or an installation is interrupted, do not immediately run a new installation. Inspect the recorded state first.

Standalone download:

```bash
bash install.sh --status
```

Full repository checkout:

```bash
bash scripts/install.sh --status
```

If it reports an incomplete transaction, review the existing config and binary state. The recommended recovery command starts a **new protected installation transaction**; it does not resume individual stages and can generate new node parameters.

Standalone download:

```bash
bash install.sh --restart-interrupted
```

Full repository checkout:

```bash
bash scripts/install.sh --restart-interrupted
```

Legacy compatibility alias:

```bash
# Standalone download
bash install.sh --resume

# Full repository checkout
bash scripts/install.sh --resume
```

`--resume` remains a legacy alias for `--restart-interrupted`; it is not stage-level resume. The new transaction can generate new node parameters, so use the final successful node output.

The root-only install state records only the stage, timestamp, selected service backend, backup path, status, and a non-secret failure reason summary. It never stores a UUID, Reality private key, SOCKS5 password, or VLESS URI.

### Configuration Test Failure

Configuration validation is a hard gate: Xray is not activated, no managed marker is created, and no client node is considered deployed until it passes. If validation fails, inspect `bash install.sh --status` for `status=FAILED` and its non-secret reason, then review `/var/log/nat-reality-bridge-install.log`. The installer restores the previous transaction state and removes the current temporary configuration, unactivated `xray.new.*` binary, and newly created client output files. Do not edit a temporary config to bypass this gate; download the current installer and start a new protected transaction only after reviewing the failure.

## Managed Installation Ownership

After a successful installation, NAT Reality Bridge writes a root-only, non-secret ownership marker at `/etc/nat-reality-bridge/managed.marker`. It contains the project name, marker format, installed version and time, and a random install ID only.

The installer, update helper, and uninstall helper require a valid marker before treating an existing Xray configuration as NAT Reality Bridge managed. Existing installations without this marker are preserved and require manual review; they are not automatically migrated, overwritten, or removed.

## Verification Semantics

`scripts/test-outbound.sh` can verify that an ISP SOCKS5 host accepts the supplied credentials. This is a **Direct SOCKS5 Test**, not proof that a VLESS Reality node works.

**Through Xray Verification** requires authenticated Reality traffic and a real client test. Confirm the public NAT endpoint from an external client, because same-host NAT hairpin tests can be misleading.

Before deployment, check:

- Memory
- Disk space
- CPU architecture
- NAT mapping
- Firewall configuration

---

# Quick Start

First-time users should start here:

**[Complete Deployment Guide](docs/full-deployment-guide.md)**

NAT Reality Bridge provides an interactive installer for environment checks, Xray Reality config generation, node URI output, and outbound testing.

If you already understand the deployment flow, download the standalone installer with `curl`:

```bash
curl -fsSL https://raw.githubusercontent.com/Molly1116/nat-reality-bridge/main/scripts/install.sh -o install.sh
sed -n '1,220p' install.sh
sed -n '221,520p' install.sh
sed -n '521,1120p' install.sh
bash install.sh
```

Or use `wget`:

```bash
wget https://raw.githubusercontent.com/Molly1116/nat-reality-bridge/main/scripts/install.sh -O install.sh
sed -n '1,220p' install.sh
bash install.sh
```

Git is not required for normal installation. If neither `curl` nor `wget` exists on the VPS, download the repository ZIP from another machine, upload the extracted project directory to the VPS, and run `bash scripts/install.sh`.

## Developer Workflow

Use Git clone when you want to read source code, modify scripts, build your own fork, or contribute to the project:

```bash
git clone https://github.com/Molly1116/nat-reality-bridge.git
cd nat-reality-bridge
```

Review the installer before execution:

```bash
sed -n '1,220p' scripts/install.sh
sed -n '221,520p' scripts/install.sh
sed -n '521,1120p' scripts/install.sh
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

Full repository users can also use helper scripts:

```bash
bash scripts/health-check.sh
bash scripts/backup.sh
bash scripts/test-outbound.sh
bash scripts/update.sh
bash scripts/uninstall.sh
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

`node.txt` is a key-value file. Import only the value after `VLESS_URI=`; do not copy the variable name. Download `node.png` from the server before scanning it on a local device.

Example completion output:

```text
NAT Reality Bridge v1.5.1

Installation completed

Status:
[OK] Xray running
[OK] Configuration valid
[OK] Outbound test passed
```

An installation is complete only after all of the following are true:

1. Xray configuration validation passed.
2. The selected backend reports Xray active or Supervisor RUNNING.
3. `/etc/nat-reality-bridge/managed.marker` exists.
4. Client node files were generated.
5. The internal Reality listener exists.
6. In ISP Mode, Direct SOCKS5 Test passed.
7. An external client completed a Reality connection.
8. Reality traffic used the intended native or ISP egress path.
9. The service remained usable after a restart.

Xray download alone is not deployment success. A running service and a passing Direct SOCKS5 Test are also not substitutes for external Reality verification.

---

# Documentation

- [Complete Deployment Guide](docs/full-deployment-guide.md)
- [完整中文部署教程](docs/full-deployment-guide.zh-CN.md)
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

# License

MIT License. See [LICENSE](LICENSE).
