# Beginner User Guide

Language: [English](#english) | [中文](#中文)

For complete first-time deployment, start with:

- [Complete Deployment Guide](full-deployment-guide.md)
- [完整中文部署教程](full-deployment-guide.zh-CN.md)

This document focuses on user operation notes after you understand the main deployment flow.

## English

This guide is for first-time users who want to deploy NAT Reality Bridge on a small NAT VPS.

NAT Reality Bridge is not a commercial node service. It is a self-hosted deployment tool. You are responsible for your own server, port mapping, proxy credentials, and client configuration.

## 1. Prepare a VPS

Recommended baseline:

- Debian 12 or Debian 13.
- x86_64 CPU architecture.
- At least 128 MB RAM.
- Swap recommended.
- Provider-side TCP port forwarding if it is a NAT VPS.
- One external TCP port mapped to the internal Xray port, usually `443`.
- `curl` or `wget`.
- `unzip` and `sha256sum`.

64 MB RAM NAT VPS instances are experimental. Xray-core is lightweight, but package installation can need more temporary memory. Avoid installing Git on this class of machine unless you have enough swap.

In v1.3.0, 64MB-class machines enter `EXTREME_LOW_RESOURCE` mode. The installer keeps the core Xray deployment path but skips QR code generation and non-essential metadata checks.

Example NAT mapping:

```text
PUBLIC_PORT -> 443/TCP
```

## 2. Log in with SSH

Use your provider's SSH information:

```bash
ssh CHANGE_ME_USER@CHANGE_ME_SERVER
```

If your provider uses a custom SSH port:

```bash
ssh -p CHANGE_ME_SSH_PORT CHANGE_ME_USER@CHANGE_ME_SERVER
```

Do not publish SSH passwords or private keys.

## 3. Get the installer

Minimal Debian NAT VPS images may not include Git. Git is not required to run NAT Reality Bridge; it is only one way to fetch the project source code.

For normal users, download the self-contained installer directly from GitHub Raw.

With `curl`:

```bash
curl -fsSL https://raw.githubusercontent.com/Molly1116/nat-reality-bridge/main/scripts/install.sh -o install.sh
```

Or with `wget`:

```bash
wget https://raw.githubusercontent.com/Molly1116/nat-reality-bridge/main/scripts/install.sh -O install.sh
```

Review the installer before running it:

```bash
sed -n '1,220p' install.sh
```

If neither `curl` nor `wget` is available, download the GitHub repository ZIP from another machine, extract it, upload the project directory to the VPS, and use the developer-style path below.

Developer workflow:

```bash
git clone https://github.com/Molly1116/nat-reality-bridge.git
cd nat-reality-bridge
```

Review the installer before running it:

```bash
sed -n '1,260p' scripts/install.sh
```

## 4. Run the installer

If you downloaded the single-file installer:

```bash
bash install.sh
```

If you cloned or uploaded the full project directory:

```bash
bash scripts/install.sh
```

After a successful installation, the tool writes a non-secret, root-only ownership marker at `/etc/nat-reality-bridge/managed.marker`. Future managed update and uninstall operations require this marker; an existing deployment without it is preserved for manual review.

Choose a deployment mode:

- Basic Mode: use the VPS native exit.
- ISP Residential Exit Mode: use a SOCKS5 ISP or residential exit.

For ISP Residential Exit Mode, prepare:

- SOCKS5 host.
- SOCKS5 port.
- Username.
- Password.

## 5. Import the client node

After installation, files are generated under:

```text
/root/nat-reality-bridge/
```

Files:

- `node.txt`: VLESS URI and client parameters.
- `node.png`: QR code, if `qrencode` was available.
- `README.txt`: short client import notes.
- `install-summary.txt`: installation summary.

Android:

- Open v2rayNG.
- Download `node.png` securely to the phone before scanning it, or copy the value after `VLESS_URI=` from `node.txt`.

Windows:

- Use Nekobox or Karing.
- Import the value after `VLESS_URI=` from `node.txt`.

iOS:

- Use Karing or another compatible client.
- Scan `node.png` or import the URI manually.

## 6. Test the deployment

For users who downloaded only `install.sh`, use the checks that are available on every installation:

```bash
ps -o pid,rss,comm -C xray
ss -tnlp | grep xray || true
/usr/local/bin/xray run -test -config /etc/xray/config.json
cat /root/nat-reality-bridge/install-summary.txt
```

If you installed from the full repository, you may also use:

```bash
bash scripts/health-check.sh
bash scripts/test-outbound.sh
```

`test-outbound.sh` is a Direct SOCKS5 Test in ISP mode. A passing result proves that the SOCKS5 proxy accepts the supplied credentials; it does not prove that the Reality node is reachable.

On an external client:

- Import the node.
- Enable the node.
- Open an IP check website.
- Confirm the exit IP matches the expected VPS or SOCKS5 exit.
- Confirm that actual traffic works through the imported Reality node. A local TCP or direct SOCKS5 test alone is not enough.

## 7. Keep useful files

For full repository users, a safe routine is:

```bash
bash scripts/health-check.sh
bash scripts/backup.sh
```

`update.sh` currently backs up and validates the current configuration only; it does not replace Xray-core automatically.

Useful paths:

```text
/etc/xray/config.json
/root/xray-backups/
/root/nat-reality-bridge/
/var/log/nat-reality-bridge-install.log
```

Never publish:

- `node.txt`
- `node.png`
- SSH credentials
- SOCKS5 credentials
- Reality privateKey

## 中文

完整首次部署流程请先阅读：

- [完整中文部署教程](full-deployment-guide.zh-CN.md)
- [Complete Deployment Guide](full-deployment-guide.md)

本文档主要补充用户操作说明，不重复完整部署教程。

本文面向第一次在小内存 NAT VPS 上部署 NAT Reality Bridge 的用户。

NAT Reality Bridge 不是商业节点服务，而是自用部署工具。服务器、端口映射、代理凭据和客户端配置都需要你自己管理。

## 1. 准备 VPS

推荐基线：

- Debian 12 或 Debian 13。
- x86_64 CPU 架构。
- 至少 128 MB 内存。
- 推荐启用 swap。
- 如果是 NAT VPS，需要服务商面板支持 TCP 端口映射。
- 一个外部 TCP 端口映射到内部 Xray 端口，通常是 `443`。
- `curl` 或 `wget`。
- `unzip` 和 `sha256sum`。

64MB RAM NAT VPS 属于实验环境。Xray-core 本身资源占用较低，但软件包安装阶段可能需要更多临时内存。除非已经有足够 swap，否则不建议在这类机器上安装 Git。

v1.3.0 中，64MB 级别机器会进入 `EXTREME_LOW_RESOURCE` 模式。安装器保留核心 Xray 部署路径，但跳过二维码生成和非必要元数据检测。

NAT 映射示例：

```text
PUBLIC_PORT -> 443/TCP
```

## 2. SSH 登录

使用服务商提供的 SSH 信息：

```bash
ssh CHANGE_ME_USER@CHANGE_ME_SERVER
```

如果服务商使用自定义 SSH 端口：

```bash
ssh -p CHANGE_ME_SSH_PORT CHANGE_ME_USER@CHANGE_ME_SERVER
```

不要公开 SSH 密码或私钥。

## 3. 获取安装器

Minimal Debian NAT VPS 默认可能没有预装 Git。Git 不是 NAT Reality Bridge 的运行依赖，只是获取项目源码的一种方式。

普通用户可以直接从 GitHub Raw 下载自包含安装器。

使用 `curl`：

```bash
curl -fsSL https://raw.githubusercontent.com/Molly1116/nat-reality-bridge/main/scripts/install.sh -o install.sh
```

或使用 `wget`：

```bash
wget https://raw.githubusercontent.com/Molly1116/nat-reality-bridge/main/scripts/install.sh -O install.sh
```

执行前先审查安装脚本：

```bash
sed -n '1,220p' install.sh
```

如果 VPS 上既没有 `curl` 也没有 `wget`，可以在其他机器下载 GitHub 仓库 ZIP，解压后上传项目目录到 VPS，再使用下面的开发者路径。

开发者流程：

```bash
git clone https://github.com/Molly1116/nat-reality-bridge.git
cd nat-reality-bridge
```

执行前先审查安装脚本：

```bash
sed -n '1,260p' scripts/install.sh
```

## 4. 执行安装

如果下载的是单文件安装器：

```bash
bash install.sh
```

如果使用的是完整项目目录：

```bash
bash scripts/install.sh
```

安装成功后，工具会在 `/etc/nat-reality-bridge/managed.marker` 写入仅 root 可读的非敏感归属标记。后续受管更新和卸载都需要该标记；没有标记的已有部署会被保留，等待人工审查。

选择部署模式：

- Basic Mode：使用 VPS 原生出口。
- ISP Residential Exit Mode：使用 SOCKS5 ISP 或家宽出口。

如果选择 ISP Residential Exit Mode，请提前准备：

- SOCKS5 地址。
- SOCKS5 端口。
- 用户名。
- 密码。

## 5. 导入客户端节点

安装完成后，文件会生成在：

```text
/root/nat-reality-bridge/
```

文件说明：

- `node.txt`：VLESS URI 和客户端参数。
- `node.png`：二维码，如果 `qrencode` 可用。
- `README.txt`：简短客户端导入说明。
- `install-summary.txt`：安装总结。

Android：

- 打开 v2rayNG。
- 先将 `node.png` 安全下载到手机后再扫码，或复制 `node.txt` 中 `VLESS_URI=` 之后的值。

Windows：

- 使用 Nekobox 或 Karing。
- 从 `node.txt` 导入 `VLESS_URI=` 之后的值。

iOS：

- 使用 Karing 或其他兼容客户端。
- 扫描 `node.png` 或手动导入 URI。

## 6. 测试部署

如果你只下载了单文件 `install.sh`，使用每个安装都可执行的检查：

```bash
ps -o pid,rss,comm -C xray
ss -tnlp | grep xray || true
/usr/local/bin/xray run -test -config /etc/xray/config.json
cat /root/nat-reality-bridge/install-summary.txt
```

如果使用的是完整仓库，还可以执行：

```bash
bash scripts/health-check.sh
bash scripts/test-outbound.sh
```

ISP 模式中，`test-outbound.sh` 只是 Direct SOCKS5 Test。通过只代表 SOCKS5 代理接受提供的凭据，不代表 Reality 节点一定可连接。

在外部客户端上：

- 导入节点。
- 启用节点。
- 打开 IP 检测网站。
- 确认出口 IP 符合预期的 VPS 或 SOCKS5 出口。
- 确认导入后的 Reality 节点可以承载实际流量；本地 TCP 或 Direct SOCKS5 测试都不足以单独证明节点可用。

## 7. 保存有用文件

完整仓库用户可以采用以下安全的日常检查与备份流程：

```bash
bash scripts/health-check.sh
bash scripts/backup.sh
```

当前 `update.sh` 只会备份和验证当前配置，不会自动替换 Xray-core。

常用路径：

```text
/etc/xray/config.json
/root/xray-backups/
/root/nat-reality-bridge/
/var/log/nat-reality-bridge-install.log
```

不要公开：

- `node.txt`
- `node.png`
- SSH 凭据
- SOCKS5 凭据
- Reality privateKey
