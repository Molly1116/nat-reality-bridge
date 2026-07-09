# Deployment

Language: [English](#english) | [中文](#中文)

## English

This document describes the generic deployment flow. Generate fresh values on every new server. Do not reuse production node parameters.

Since v1.2.0, `scripts/install.sh` is an interactive installer. It performs environment checks, asks for the deployment mode, generates fresh Reality values, tests a temporary config, backs up the old config, and restarts Xray only after validation succeeds.

After installation, client files and the install summary are written to `/root/nat-reality-bridge/`.

### 1. Environment Check

```bash
date -Is
uname -a
cat /etc/os-release
systemd-detect-virt -v || true
systemd-detect-virt --container || true
ip -br addr
ip route show
ss -tnlp
free -h
df -hT
```

Confirm:

- Debian 12/13 or compatible system.
- x86_64 architecture.
- 128 MB RAM or above is recommended.
- Swap is recommended on low-memory nodes.
- NAT VPS requires provider-side TCP forwarding.
- systemd is available.

Minimal Debian NAT VPS images may not include Git. Git is not a runtime dependency; it is only one way to fetch the project source code.

64 MB RAM NAT VPS instances are experimental. Xray-core itself is lightweight, but Debian package installation can require more temporary memory. `apt install git` may be killed by OOM on this class of machine, so avoid Git clone as the default workflow there.

### 2. NAT Port Mapping

Create a provider-side TCP mapping:

```text
PUBLIC_ENDPOINT_PORT -> INTERNAL_XRAY_PORT
```

Keeping the internal Xray port as `443` is recommended. The external port is determined by the provider.

### 3. Xray Installation

Automated path:

```bash
bash scripts/install.sh
```

Review the script before running it. Do not execute installation scripts blindly on a production machine.

For normal users, do not assume Git is available. Future versions may provide a lighter download-based installation path. Until then, use Git clone mainly for source review, development, forks, and contributions.

Developer workflow:

```bash
git clone https://github.com/Molly1116/nat-reality-bridge.git
cd nat-reality-bridge
```

The installer supports two modes:

- Basic Mode: VLESS Reality TCP Vision with VPS native exit.
- ISP Residential Exit Mode: VLESS Reality TCP Vision with SOCKS5 ISP or residential exit.

Use official Xray-core release assets and verify checksums before installing:

```text
Xray-linux-64.zip
Xray-linux-64.zip.dgst
```

Recommended paths:

```text
/usr/local/bin/xray
/usr/local/share/xray/geoip.dat
/usr/local/share/xray/geosite.dat
/etc/xray/config.json
/etc/systemd/system/xray.service
```

### 4. Reality Configuration

Recommended verified profile:

```text
serverName: www.cloudflare.com
dest: www.cloudflare.com:443
spiderX: /
flow: xtls-rprx-vision
```

Generate fresh values on every server:

```bash
UUID=$(/usr/local/bin/xray uuid)
/usr/local/bin/xray x25519
SHORT_ID=$(od -An -N8 -tx1 /dev/urandom | tr -d ' \n')
```

### 5. Egress Mode

Basic Mode uses a `freedom` outbound and exits through the VPS native network.

ISP Residential Exit Mode configures a `socks` outbound and routes all `tcp,udp` traffic to it. Keep proxy credentials out of public repositories.

### 6. Validation

```bash
/usr/local/bin/xray run -test -config /etc/xray/config.json
systemctl restart xray
systemctl is-active xray
ss -tnlp | grep ':443'
journalctl -u xray --no-pager -n 80
```

In Basic Mode, the final client exit IP should match the VPS native exit. In ISP Residential Exit Mode, the final client exit IP should match the SOCKS5 ISP exit IP.

v1.2.0 also provides:

```bash
bash scripts/test-outbound.sh
bash scripts/health-check.sh
```

## 中文

本文描述通用部署流程。所有值都应在新机器上重新生成，不要复用旧节点参数。

从 v1.2.0 开始，`scripts/install.sh` 是交互式安装器。它会执行环境检查、询问部署模式、生成新的 Reality 参数、测试临时配置、备份旧配置，并且只在验证成功后重启 Xray。

安装完成后，客户端文件和安装总结会写入 `/root/nat-reality-bridge/`。

### 1. 环境检查

```bash
date -Is
uname -a
cat /etc/os-release
systemd-detect-virt -v || true
systemd-detect-virt --container || true
ip -br addr
ip route show
ss -tnlp
free -h
df -hT
```

确认：

- 系统为 Debian 12/13 或兼容环境。
- 架构为 x86_64。
- 推荐 128MB RAM 或更高。
- 小内存节点推荐启用 swap。
- 服务端只有内网地址时，需依赖服务商 NAT 映射。
- systemd 可用。

Minimal Debian NAT VPS 默认可能没有预装 Git。Git 不是运行依赖，只是获取项目源码的一种方式。

64MB RAM NAT VPS 属于实验环境。Xray-core 本身资源占用较低，但 Debian 软件包安装阶段可能需要更多临时内存。`apt install git` 可能在这类机器上因为 OOM 被系统终止，因此不建议把 Git clone 作为默认流程。

### 2. NAT 端口

在服务商面板添加 TCP 映射：

```text
PUBLIC_ENDPOINT_PORT -> INTERNAL_XRAY_PORT
```

建议让内部 Xray 端口保持为 `443`，外部端口由服务商映射决定。

### 3. 安装 Xray

自动化方式：

```bash
bash scripts/install.sh
```

执行前必须审查脚本，不要在生产机器上盲目运行安装脚本。

普通用户流程不应默认假设 Git 可用。未来版本可能提供更轻量的下载式安装路径；在此之前，Git clone 主要用于源码审查、开发、fork 和贡献。

开发者流程：

```bash
git clone https://github.com/Molly1116/nat-reality-bridge.git
cd nat-reality-bridge
```

安装器支持两种模式：

- Basic Mode：VLESS Reality TCP Vision，使用 VPS 原生出口。
- ISP Residential Exit Mode：VLESS Reality TCP Vision，使用 SOCKS5 ISP 或家宽出口。

使用官方 Xray-core release，并校验下载文件：

```text
Xray-linux-64.zip
Xray-linux-64.zip.dgst
```

推荐路径：

```text
/usr/local/bin/xray
/usr/local/share/xray/geoip.dat
/usr/local/share/xray/geosite.dat
/etc/xray/config.json
/etc/systemd/system/xray.service
```

### 4. Reality 配置

推荐已验证参数：

```text
serverName: www.cloudflare.com
dest: www.cloudflare.com:443
spiderX: /
flow: xtls-rprx-vision
```

每台机器都要重新生成：

```bash
UUID=$(/usr/local/bin/xray uuid)
/usr/local/bin/xray x25519
SHORT_ID=$(od -An -N8 -tx1 /dev/urandom | tr -d ' \n')
```

### 5. 出口模式

Basic Mode 使用 `freedom` outbound，通过 VPS 原生网络出口。

ISP Residential Exit Mode 配置 `socks` outbound，并将全部 `tcp,udp` 路由到该 outbound。敏感参数应通过交互输入或环境变量提供，不要写入公开仓库。

### 6. 验证

```bash
/usr/local/bin/xray run -test -config /etc/xray/config.json
systemctl restart xray
systemctl is-active xray
ss -tnlp | grep ':443'
journalctl -u xray --no-pager -n 80
```

Basic Mode 下，最终客户端出口 IP 应等于 VPS 原生出口。ISP Residential Exit Mode 下，最终客户端出口 IP 应等于 SOCKS5 ISP 出口 IP。

v1.2.0 还提供：

```bash
bash scripts/test-outbound.sh
bash scripts/health-check.sh
```
