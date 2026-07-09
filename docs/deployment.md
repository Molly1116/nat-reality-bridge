# Deployment

Language: [English](#english) | [中文](#中文)

## English

This document describes the generic deployment flow. Generate fresh values on every new server. Do not reuse production node parameters.

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
- NAT VPS requires provider-side TCP forwarding.
- systemd is available.

### 2. NAT Port Mapping

Create a provider-side TCP mapping:

```text
PUBLIC_ENDPOINT_PORT -> INTERNAL_XRAY_PORT
```

Keeping the internal Xray port as `443` is recommended. The external port is determined by the provider.

### 3. Xray Installation

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

### 5. SOCKS5 Egress

Configure a `socks` outbound and route all `tcp,udp` traffic to it. Keep proxy credentials out of public repositories.

### 6. Validation

```bash
/usr/local/bin/xray run -test -config /etc/xray/config.json
systemctl restart xray
systemctl is-active xray
ss -tnlp | grep ':443'
journalctl -u xray --no-pager -n 80
```

The final client exit IP should match the SOCKS5 ISP exit IP.

## 中文

本文描述通用部署流程。所有值都应在新机器上重新生成，不要复用旧节点参数。

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
- 服务端只有内网地址时，需依赖服务商 NAT 映射。
- systemd 可用。

### 2. NAT 端口

在服务商面板添加 TCP 映射：

```text
PUBLIC_ENDPOINT_PORT -> INTERNAL_XRAY_PORT
```

建议让内部 Xray 端口保持为 `443`，外部端口由服务商映射决定。

### 3. 安装 Xray

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

### 5. SOCKS5 出口

配置 `socks` outbound，并将全部 `tcp,udp` 路由到该 outbound。敏感参数应通过交互输入或环境变量提供，不要写入公开仓库。

### 6. 验证

```bash
/usr/local/bin/xray run -test -config /etc/xray/config.json
systemctl restart xray
systemctl is-active xray
ss -tnlp | grep ':443'
journalctl -u xray --no-pager -n 80
```

最终客户端出口 IP 应等于 SOCKS5 ISP 出口 IP。