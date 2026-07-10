# Complete Deployment Guide

完整部署教程：NAT VPS Entry + Xray Reality + optional ISP Residential SOCKS5 Exit

This guide is for first-time users who want to deploy NAT Reality Bridge from zero to a usable client node. It uses placeholder values only. Replace every `CHANGE_ME_*` value with your own server or proxy information.

本文档面向第一次部署用户，覆盖从准备 VPS 到客户端导入节点的完整流程。所有示例都使用占位符，请将 `CHANGE_ME_*` 替换为你自己的服务器或代理参数。

## 1. What This Project Does / 项目用途

NAT Reality Bridge helps you build a low-resource Xray Reality entry node on a NAT VPS.

The design separates two responsibilities:

- Entry node: network path, NAT port mapping, and Reality access.
- Exit node: final public egress IP, optionally provided by SOCKS5 ISP Residential proxy.

Two deployment modes are supported:

- Basic Mode: Xray exits through the VPS native network.
- ISP Residential Exit Mode: Xray routes traffic through a SOCKS5 ISP Residential outbound.

This project is not a commercial proxy service and does not guarantee access to any specific website or application.

## 2. Prepare a NAT VPS / 准备 NAT VPS

Recommended baseline:

- Debian 12 or Debian 13
- x86_64
- systemd
- 128 MB RAM or above
- Swap recommended
- NAT VPS with provider-side TCP port forwarding

64 MB RAM NAT VPS is experimental. The installer keeps the core Xray deployment path but skips optional work in extreme low-resource mode.

Record these values before installation:

```text
SSH host: CHANGE_ME_SERVER
SSH port: CHANGE_ME_SSH_PORT
SSH user: root
Public entry host: CHANGE_ME_PUBLIC_HOST
Public entry port: CHANGE_ME_PUBLIC_PORT
Internal Xray port: 443
NAT mapping: CHANGE_ME_PUBLIC_HOST:CHANGE_ME_PUBLIC_PORT -> internal 443/TCP
```

The provider-side NAT rule should forward one external TCP port to internal TCP port `443`.

Example Test Environment:

This project does not recommend any provider. The following reference is only a test environment used to validate the architecture and reproduce deployment steps. Pricing, inventory, route quality, and service quality may change.

- Name: Test NAT VPS
- Type: NAT VPS
- Region: Los Angeles, US
- Purpose: Xray Reality entry node
- Reference: https://dash.fuckip.me

You may use any NAT VPS that meets the requirements above.

## 3. Prepare Static ISP Residential SOCKS5 / 准备 ISP SOCKS5

This step is only required for ISP Residential Exit Mode.

Prepare:

```text
SOCKS5 host: CHANGE_ME_SOCKS5_HOST
SOCKS5 port: CHANGE_ME_SOCKS5_PORT
SOCKS5 username: CHANGE_ME_SOCKS5_USER
SOCKS5 password: CHANGE_ME_SOCKS5_PASSWORD
```

Skip this section if you plan to use Basic Mode.

Example Test Environment:

This project does not recommend any provider. The following reference is only a test environment used to validate ISP Residential Exit Mode.

- Name: ISP Residential SOCKS5
- Type: Static ISP Residential SOCKS5
- Region: Los Angeles, US
- Purpose: final public egress IP
- Reference: https://www.711proxy.com/signup?code=20560D
- Selection reason: supports IP range inspection, which helps region filtering during tests

You may use another ISP Residential Proxy provider. Evaluate price, availability, IP quality, and provider policy independently.

## 4. SSH Login / SSH 登录

Connect to the VPS:

```bash
ssh -p CHANGE_ME_SSH_PORT root@CHANGE_ME_SERVER
```

Do not publish SSH passwords or private keys.

## 5. Basic System Checks / 基础系统检查

Run these commands before installing:

```bash
date -Is
uname -a
cat /etc/os-release
free -h
df -hT
systemd-detect-virt -v || true
ip -br addr
ip route show
ss -tnlp
command -v curl || command -v wget || true
command -v unzip || true
command -v sha256sum || true
systemctl --version
```

Expected:

- Debian 12 or Debian 13
- x86_64 architecture
- systemd available
- at least one of `curl` or `wget`
- `unzip` and `sha256sum` available
- enough free disk under `/usr/local`

If `git` is missing, that is normal. Git is not required for the normal user installation workflow.

## 6. Download install.sh / 获取 install.sh

Normal users can download the standalone installer.

Using `curl`:

```bash
curl -fsSL https://raw.githubusercontent.com/Molly1116/nat-reality-bridge/main/scripts/install.sh -o install.sh
```

Using `wget`:

```bash
wget https://raw.githubusercontent.com/Molly1116/nat-reality-bridge/main/scripts/install.sh -O install.sh
```

If neither `curl` nor `wget` exists, download the GitHub repository ZIP on another machine, extract it, upload the project directory to the VPS, and run the full-repository command later:

```bash
bash scripts/install.sh
```

## 7. Review the Script / 审查脚本

Always review installation scripts before running them:

```bash
sed -n '1,220p' install.sh
sed -n '220,520p' install.sh
sed -n '520,760p' install.sh
```

If you are using the full repository instead of the standalone file:

```bash
sed -n '1,220p' scripts/install.sh
sed -n '220,520p' scripts/install.sh
sed -n '520,760p' scripts/install.sh
```

## 8. Run the Installer / 执行安装

For standalone `install.sh`:

```bash
bash install.sh
```

For full repository users:

```bash
bash scripts/install.sh
```

The installer will show a plan before applying changes. Continue only after you confirm the values are correct.

## 9. Choose Basic Mode or ISP Mode / 选择模式

The installer asks for a deployment mode.

Choose Basic Mode when:

- you want the simplest deployment
- you want to use the VPS native exit
- you do not have a SOCKS5 ISP Residential proxy

Choose ISP Residential Exit Mode when:

- you want entry/exit separation
- you want the final egress to use a SOCKS5 ISP Residential proxy
- you already have SOCKS5 host, port, username, and password

## 10. Fill ISP Parameters / 填写 ISP 参数

Only ISP Residential Exit Mode asks for SOCKS5 parameters.

Use your real values during installation:

```text
SOCKS5 Host: CHANGE_ME_SOCKS5_HOST
SOCKS5 Port: CHANGE_ME_SOCKS5_PORT
Username: CHANGE_ME_SOCKS5_USER
Password: CHANGE_ME_SOCKS5_PASSWORD
```

Do not commit SOCKS5 credentials to GitHub.

## 11. Get the Client Node / 获取节点

After installation, client files are generated under:

```text
/root/nat-reality-bridge/
```

Check generated files:

```bash
ls -lah /root/nat-reality-bridge/
cat /root/nat-reality-bridge/node.txt
cat /root/nat-reality-bridge/install-summary.txt
```

Expected files:

- `node.txt`: VLESS URI and client parameters
- `node.png`: QR code, when `qrencode` is available
- `README.txt`: client import notes
- `install-summary.txt`: mode, Xray status, config test result, and install time

## 12. Import Client / 客户端导入

Android:

- Open v2rayNG.
- Scan `/root/nat-reality-bridge/node.png` if it exists.
- Or copy the `vless://` URI from `/root/nat-reality-bridge/node.txt`.

Windows:

- Use Karing, Nekobox, or another compatible client.
- Import the `vless://` URI from `/root/nat-reality-bridge/node.txt`.

iOS:

- Use Karing or another compatible client.
- Scan the QR code or import the URI manually.

If no QR code was generated, use:

```bash
cat /root/nat-reality-bridge/node.txt
```

## 13. Service Checks / 服务检查

These commands work for both standalone installer users and full repository users:

```bash
systemctl status xray --no-pager
ss -tnlp | grep xray || true
/usr/local/bin/xray run -test -config /etc/xray/config.json
cat /root/nat-reality-bridge/install-summary.txt
```

If you installed from the full repository, helper scripts are also available:

```bash
bash scripts/health-check.sh
bash scripts/test-outbound.sh
```

Do not run `scripts/health-check.sh` or `scripts/test-outbound.sh` after a standalone `install.sh` download unless you also uploaded the full repository.

## 14. Common Issues / 常见问题

### git: command not found

Normal users do not need Git. Use the standalone installer:

```bash
curl -fsSL https://raw.githubusercontent.com/Molly1116/nat-reality-bridge/main/scripts/install.sh -o install.sh
bash install.sh
```

Or:

```bash
wget https://raw.githubusercontent.com/Molly1116/nat-reality-bridge/main/scripts/install.sh -O install.sh
bash install.sh
```

### apt install git was killed

This can happen on 64 MB class VPS nodes because package installation can temporarily require more memory than Xray runtime needs.

Use the standalone installer workflow and avoid installing Git on extreme low-resource machines.

### curl and wget are both missing

Download the GitHub repository ZIP on another machine, extract it, upload the project directory to the VPS, and run:

```bash
bash scripts/install.sh
```

### unzip is missing

`unzip` is required because the official Xray-core release asset is a zip file. Install it only if your VPS has enough memory and you accept the package installation risk on very small machines.

### node.png is missing

QR generation is optional. The node URI is still available:

```bash
cat /root/nat-reality-bridge/node.txt
```

### Reality client cannot connect

Check:

```bash
systemctl status xray --no-pager
ss -tnlp | grep xray || true
/usr/local/bin/xray run -test -config /etc/xray/config.json
cat /root/nat-reality-bridge/node.txt
```

Also confirm your provider NAT rule forwards the public TCP port to internal `443`.

### NAT port mapping is wrong

Verify the provider panel mapping:

```text
CHANGE_ME_PUBLIC_HOST:CHANGE_ME_PUBLIC_PORT -> internal 443/TCP
```

Then check Xray listening state:

```bash
ss -tnlp | grep xray || true
```

### ISP SOCKS5 test failed

Check SOCKS5 host, port, username, password, provider allowlist rules, and whether the proxy provider allows connections from your VPS.

Review the install summary:

```bash
cat /root/nat-reality-bridge/install-summary.txt
```

### Exit IP is not the expected ISP IP

In Basic Mode, the exit IP should be the VPS native IP.

In ISP Residential Exit Mode, the exit IP should be the SOCKS5 provider's IP. If it is not, verify SOCKS5 credentials and the generated Xray config:

```bash
/usr/local/bin/xray run -test -config /etc/xray/config.json
```
