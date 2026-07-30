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
- a usable systemd service bus, or an existing working Supervisor instance
- 128 MB RAM or above
- Swap recommended
- NAT VPS with provider-side TCP port forwarding

64 MB RAM NAT VPS is experimental. The installer does not install extra software automatically and may stop safely if an extreme container lacks required tools or a reliable service manager. Use 128 MB RAM or above, with swap enabled, as the recommended minimum.

### Service Backend

`systemctl` being installed does not prove systemd can manage services. The installer verifies PID 1 and the system bus:

- A usable systemd backend manages `xray.service`.
- A restricted container can use an already-running Supervisor instance.
- Without either backend, installation stops before activating Xray.

The installer never installs Supervisor automatically.

### DNS Note

NAT Reality Bridge does not ask for a custom DNS server and does not modify the VPS resolver. DNS setup is not a separate deployment step. Before installation, you may confirm that the VPS can resolve the Reality target:

```bash
getent hosts www.cloudflare.com || true
```

If this check fails, resolve the VPS networking or DNS issue with your provider before installing. Do not substitute the ISP SOCKS5 exit address for the public entry host.

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

Important: `Public entry host` and `Public entry port` mean the NAT VPS Entry Node. Do not enter the ISP Residential SOCKS5 exit IP as the Reality public host.

```text
NAT VPS Entry:
- Public IP or domain: CHANGE_ME_PUBLIC_HOST
- Public NAT port: CHANGE_ME_PUBLIC_PORT
- Internal Xray port: 443

ISP Residential Exit:
- SOCKS5 host: CHANGE_ME_SOCKS5_HOST
- SOCKS5 port: CHANGE_ME_SOCKS5_PORT
- Username: CHANGE_ME_SOCKS5_USER
- Password: CHANGE_ME_SOCKS5_PASSWORD
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

### Recommended ISP SOCKS5 Exit For Personal Self-Hosting

Based on current testing and price experience, Webshare Private Proxy is a more suitable recommendation for a personal self-hosted node.

- Type: Private Proxy / authenticated SOCKS5
- Reference: https://www.webshare.io/?referral_code=42f1h0pjvt1z

Personal-use guidance:

- Choose a Private Proxy rather than a shared proxy.
- Prefer a dedicated egress and keep the SOCKS5 credentials private.
- Buy multiple candidate IPs within your budget, then replace and test them manually.

IP selection process:

1. Obtain candidate IPs.
2. Check the observed exit ASN and ISP.
3. Test access to the services you need.
4. Test latency and stability from your own network.
5. Keep the IP that performs best for your use case.

Multiple candidates can improve the chance of finding a suitable egress IP. They do not guarantee that every IP is high quality. You may use another authenticated SOCKS5 provider when it better fits your requirements.

## 4. SSH Login / SSH 登录

Connect to the VPS:

```bash
ssh -p CHANGE_ME_SSH_PORT root@CHANGE_ME_SERVER
```

Do not publish SSH passwords or private keys.

Linux terminals do not display password characters while you type or paste. They also do not show `*`. Paste the password once and press Enter.

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
- a usable systemd service bus, or an already-running Supervisor instance
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

When the installer shows:

```text
Continue? Type yes:
```

Type the full word `yes` and press Enter. Pressing Enter without `yes` cancels the installation.

### Existing Configuration Protection

The installer is for a supported single-node configuration. Before it modifies an existing config, it requires a valid root-only ownership marker at `/etc/nat-reality-bridge/managed.marker`. The marker contains project metadata and a random install ID only.

Without a valid marker, the existing Xray deployment is treated as user-managed and preserved. It is not automatically migrated, overwritten, or removed. A marker-backed config must still be the supported single-node structure; multi-inbound, multi-outbound, and unrecognized configurations stop safely. This project does not manage multi-ISP Xray configurations.

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

To print only the importable URI, use:

```bash
sed -n 's/^VLESS_URI=//p' /root/nat-reality-bridge/node.txt
```

Expected files:

- `node.txt`: VLESS URI and client parameters
- `node.png`: QR code, when `qrencode` is available
- `README.txt`: client import notes
- `install-summary.txt`: mode, Xray status, config test result, and install time

## 12. Import Client / 客户端导入

Android:

- Open v2rayNG.
- Download `/root/nat-reality-bridge/node.png` to the phone before scanning it, if it exists.
- Or copy the value after `VLESS_URI=` from `/root/nat-reality-bridge/node.txt`.

Windows:

- Use Karing, Nekobox, or another compatible client.
- Import the value after `VLESS_URI=` from `/root/nat-reality-bridge/node.txt`.

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
ps -o pid,rss,comm -C xray
ss -tnlp | grep xray || true
/usr/local/bin/xray run -test -config /etc/xray/config.json
cat /root/nat-reality-bridge/install-summary.txt
```

If you installed from the full repository, helper scripts are also available:

```bash
bash scripts/health-check.sh
bash scripts/test-outbound.sh
```

`health-check.sh` detects systemd, Supervisor, or an unknown backend. Do not assume `systemctl status xray` is valid merely because the command exists.

Do not run `scripts/health-check.sh` or `scripts/test-outbound.sh` after a standalone `install.sh` download unless you also uploaded the full repository.

`test-outbound.sh` performs a **Direct SOCKS5 Test** only. A successful result proves SOCKS5 reachability and credentials, not a Reality handshake. Verify the completed client node from an external client to test the public NAT path and authenticated Through Xray traffic.

For routine maintenance from a full repository checkout:

```bash
bash scripts/health-check.sh
bash scripts/backup.sh
```

`update.sh` currently creates a backup and validates the current Xray configuration; it does not replace Xray-core automatically.

## Installation Recovery

If SSH disconnects or installation stops unexpectedly, do not immediately run a new installation. Check the root-only state file first.

For a standalone download:

```bash
bash install.sh --status
```

For a full repository checkout:

```bash
bash scripts/install.sh --status
```

When it reports an incomplete transaction, inspect the existing config and binary state. Recovery starts a **new protected installation transaction**; it does not resume individual stages and can generate new node parameters.

For a standalone download:

```bash
bash install.sh --restart-interrupted
```

For a full repository checkout:

```bash
bash scripts/install.sh --restart-interrupted
```

`--resume` remains available as a legacy alias.

`install-state` stores only the stage, timestamp, service backend, backup path, and status. It never stores UUIDs, Reality private keys, SOCKS5 passwords, or VLESS URIs.

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
ps -eo pid,comm,args | grep '[x]ray' || true
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
