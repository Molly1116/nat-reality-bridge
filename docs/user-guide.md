# Beginner User Guide

Language: [English](#english) | [中文](#中文)

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

In v1.3.0, 64MB-class machines enter `EXTREME_LOW_RESOURCE` mode. The installer keeps the core Xray deployment path but skips optional QR dependency installation and non-essential metadata checks.

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

Future versions may provide a lighter download-based installation path. This guide does not provide an unverified one-command installer.

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

```bash
bash scripts/install.sh
```

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
- Scan `node.png`, or copy the `vless://` URI from `node.txt`.

Windows:

- Use Nekobox or Karing.
- Import the `vless://` URI from `node.txt`.

iOS:

- Use Karing or another compatible client.
- Scan `node.png` or import the URI manually.

## 6. Test the deployment

On the server:

```bash
bash scripts/health-check.sh
bash scripts/test-outbound.sh
```

On the client:

- Import the node.
- Enable the node.
- Open an IP check website.
- Confirm the exit IP matches the expected VPS or SOCKS5 exit.

## 7. Keep useful files

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

v1.3.0 中，64MB 级别机器会进入 `EXTREME_LOW_RESOURCE` 模式。安装器保留核心 Xray 部署路径，但跳过可选二维码依赖安装和非必要元数据检测。

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

未来版本可能提供更轻量的下载式安装路径。本文档不提供未经验证的一键安装命令。

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

```bash
bash scripts/install.sh
```

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
- 扫描 `node.png`，或复制 `node.txt` 中的 `vless://` URI。

Windows：

- 使用 Nekobox 或 Karing。
- 从 `node.txt` 导入 `vless://` URI。

iOS：

- 使用 Karing 或其他兼容客户端。
- 扫描 `node.png` 或手动导入 URI。

## 6. 测试部署

在服务器上执行：

```bash
bash scripts/health-check.sh
bash scripts/test-outbound.sh
```

在客户端上：

- 导入节点。
- 启用节点。
- 打开 IP 检测网站。
- 确认出口 IP 符合预期的 VPS 或 SOCKS5 出口。

## 7. 保存有用文件

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
