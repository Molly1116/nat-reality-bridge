# 完整部署教程

NAT VPS Entry + Xray Reality + 可选 ISP Residential SOCKS5 Exit

本文档面向第一次部署 NAT Reality Bridge 的用户，目标是从准备服务器到客户端导入节点完整走通一次。所有示例均使用占位符，请将 `CHANGE_ME_*` 替换成你自己的真实参数。

## 1. 项目介绍

NAT Reality Bridge 用于在低资源 NAT VPS 上部署一个极简 Xray Reality 入口节点。

核心思想：

- 入口节点负责网络路径、NAT 端口映射和 Reality 接入。
- 出口节点负责最终公网出口 IP，可选使用 SOCKS5 ISP Residential 代理。

支持两种模式：

- Basic Mode：使用 VPS 原生网络出口。
- ISP Residential Exit Mode：通过 SOCKS5 ISP Residential outbound 出口。

本项目不是商业代理服务，不售卖节点，也不保证任何具体网站或应用一定可用。

## 2. 准备 NAT VPS

推荐配置：

- Debian 12 或 Debian 13
- x86_64 架构
- systemd 可用
- 128MB RAM 或更高
- 推荐启用 swap
- NAT VPS 支持服务商侧 TCP 端口映射

64MB RAM NAT VPS 属于实验环境。安装器会保留核心 Xray 部署流程，但会在极低资源模式下跳过非必要步骤。

部署前记录这些信息：

```text
SSH 主机: CHANGE_ME_SERVER
SSH 端口: CHANGE_ME_SSH_PORT
SSH 用户: root
公网入口地址: CHANGE_ME_PUBLIC_HOST
公网入口端口: CHANGE_ME_PUBLIC_PORT
内部 Xray 端口: 443
NAT 映射: CHANGE_ME_PUBLIC_HOST:CHANGE_ME_PUBLIC_PORT -> 内部 443/TCP
```

服务商控制面板中应添加一条 TCP NAT 映射，将公网端口转发到 VPS 内部 `443` 端口。

### 测试环境参考

本项目不推荐任何供应商。以下环境仅用于作者测试、验证架构和帮助用户复现部署流程。价格、库存、线路和服务质量都可能变化，请自行评估。

- 名称：Test NAT VPS
- 类型：NAT VPS
- 地区：美国洛杉矶
- 用途：Xray Reality 入口节点
- 参考链接：https://dash.fuckip.me

你也可以选择任何符合上述要求的 NAT VPS。

## 3. 准备静态 ISP Residential SOCKS5

只有 ISP Residential Exit Mode 需要此步骤。Basic Mode 可以跳过。

请提前准备：

```text
SOCKS5 Host: CHANGE_ME_SOCKS5_HOST
SOCKS5 Port: CHANGE_ME_SOCKS5_PORT
Username: CHANGE_ME_SOCKS5_USER
Password: CHANGE_ME_SOCKS5_PASSWORD
```

### 测试环境参考

本项目不推荐任何供应商。以下环境仅用于验证 ISP Residential Exit Mode。

- 名称：ISP Residential SOCKS5
- 类型：Static ISP Residential SOCKS5
- 地区：美国洛杉矶
- 用途：提供最终公网出口 IP
- 参考链接：https://www.711proxy.com/signup?code=20560D
- 选择原因：支持查看 IP 段，便于测试时筛选地区

你可以选择其他 ISP Residential Proxy 服务。请自行评估价格、库存、IP 质量和服务商策略。

## 4. SSH 登录

连接 VPS：

```bash
ssh -p CHANGE_ME_SSH_PORT root@CHANGE_ME_SERVER
```

不要公开 SSH 密码或私钥。

## 5. 系统检查

安装前执行：

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

期望结果：

- Debian 12 或 Debian 13
- x86_64 架构
- systemd 可用
- 至少存在 `curl` 或 `wget` 之一
- 存在 `unzip` 和 `sha256sum`
- `/usr/local` 下有足够空间

如果系统没有 Git，这是正常的。普通用户安装流程不需要 Git。

## 6. 下载 install.sh

普通用户可以直接下载单文件安装器。

使用 `curl`：

```bash
curl -fsSL https://raw.githubusercontent.com/Molly1116/nat-reality-bridge/main/scripts/install.sh -o install.sh
```

使用 `wget`：

```bash
wget https://raw.githubusercontent.com/Molly1116/nat-reality-bridge/main/scripts/install.sh -O install.sh
```

如果 VPS 上既没有 `curl` 也没有 `wget`，可以在另一台机器下载 GitHub 仓库 ZIP，解压后上传项目目录到 VPS，然后使用完整仓库命令：

```bash
bash scripts/install.sh
```

## 7. 审查脚本

执行任何安装脚本前都应该先审查内容：

```bash
sed -n '1,220p' install.sh
sed -n '220,520p' install.sh
sed -n '520,760p' install.sh
```

如果你使用的是完整仓库：

```bash
sed -n '1,220p' scripts/install.sh
sed -n '220,520p' scripts/install.sh
sed -n '520,760p' scripts/install.sh
```

## 8. 执行安装

如果下载的是单文件 `install.sh`：

```bash
bash install.sh
```

如果使用完整仓库：

```bash
bash scripts/install.sh
```

安装器会在真正应用配置前显示计划。确认参数正确后再继续。

## 9. Basic Mode / ISP Mode 选择

安装器会要求选择部署模式。

选择 Basic Mode 的情况：

- 你想使用最简单的部署方式。
- 你想使用 VPS 原生出口。
- 你没有 SOCKS5 ISP Residential 代理。

选择 ISP Residential Exit Mode 的情况：

- 你需要入口/出口分离。
- 你希望最终公网出口使用 SOCKS5 ISP Residential。
- 你已经准备好 SOCKS5 Host、Port、Username、Password。

## 10. ISP 参数填写

只有 ISP Residential Exit Mode 会要求填写 SOCKS5 参数。

安装过程中输入你的真实参数：

```text
SOCKS5 Host: CHANGE_ME_SOCKS5_HOST
SOCKS5 Port: CHANGE_ME_SOCKS5_PORT
Username: CHANGE_ME_SOCKS5_USER
Password: CHANGE_ME_SOCKS5_PASSWORD
```

不要把 SOCKS5 凭据提交到 GitHub。

## 11. 获取节点

安装完成后，客户端文件会生成在：

```text
/root/nat-reality-bridge/
```

查看生成文件：

```bash
ls -lah /root/nat-reality-bridge/
cat /root/nat-reality-bridge/node.txt
cat /root/nat-reality-bridge/install-summary.txt
```

预计文件：

- `node.txt`：VLESS URI 和客户端参数。
- `node.png`：二维码，存在 `qrencode` 时生成。
- `README.txt`：客户端导入说明。
- `install-summary.txt`：部署模式、Xray 状态、配置测试结果和安装时间。

## 12. 客户端导入

Android：

- 打开 v2rayNG。
- 如果存在 `/root/nat-reality-bridge/node.png`，可以扫码导入。
- 也可以复制 `/root/nat-reality-bridge/node.txt` 中的 `vless://` URI。

Windows：

- 使用 Karing、Nekobox 或其他兼容客户端。
- 从 `/root/nat-reality-bridge/node.txt` 导入 `vless://` URI。

iOS：

- 使用 Karing 或其他兼容客户端。
- 扫描二维码或手动导入 URI。

如果没有生成二维码，使用：

```bash
cat /root/nat-reality-bridge/node.txt
```

## 13. 服务检查

以下命令适用于单文件安装用户和完整仓库用户：

```bash
systemctl status xray --no-pager
ss -tnlp | grep xray || true
/usr/local/bin/xray run -test -config /etc/xray/config.json
cat /root/nat-reality-bridge/install-summary.txt
```

如果你使用完整仓库，也可以运行辅助脚本：

```bash
bash scripts/health-check.sh
bash scripts/test-outbound.sh
```

如果你只是下载了单文件 `install.sh`，不要调用 `scripts/health-check.sh` 或 `scripts/test-outbound.sh`，除非你也上传了完整仓库。

## 14. 常见问题

### git: command not found

普通用户不需要 Git。使用单文件安装器：

```bash
curl -fsSL https://raw.githubusercontent.com/Molly1116/nat-reality-bridge/main/scripts/install.sh -o install.sh
bash install.sh
```

或：

```bash
wget https://raw.githubusercontent.com/Molly1116/nat-reality-bridge/main/scripts/install.sh -O install.sh
bash install.sh
```

### apt install git 被 Killed

64MB 级别 VPS 上可能出现这种情况，因为软件包安装阶段可能需要比 Xray 运行时更多的临时内存。

极低资源机器建议使用单文件安装流程，不要为了部署本项目而安装 Git。

### curl 和 wget 都不存在

在另一台机器下载 GitHub 仓库 ZIP，解压后上传项目目录到 VPS，然后执行：

```bash
bash scripts/install.sh
```

### unzip 不存在

`unzip` 是必需的，因为官方 Xray-core release 文件是 zip 格式。极低内存机器上安装软件包可能有风险，请确认有足够内存或 swap。

### node.png 不存在

二维码是可选输出。节点 URI 仍然保存在：

```bash
cat /root/nat-reality-bridge/node.txt
```

### Reality 客户端无法连接

检查：

```bash
systemctl status xray --no-pager
ss -tnlp | grep xray || true
/usr/local/bin/xray run -test -config /etc/xray/config.json
cat /root/nat-reality-bridge/node.txt
```

同时确认服务商 NAT 规则将公网 TCP 端口转发到内部 `443`。

### NAT 端口映射错误

确认服务商控制面板中的映射：

```text
CHANGE_ME_PUBLIC_HOST:CHANGE_ME_PUBLIC_PORT -> 内部 443/TCP
```

然后检查 Xray 监听状态：

```bash
ss -tnlp | grep xray || true
```

### ISP SOCKS5 测试失败

检查 SOCKS5 Host、Port、Username、Password、服务商白名单规则，以及代理服务商是否允许当前 VPS 连接。

查看安装总结：

```bash
cat /root/nat-reality-bridge/install-summary.txt
```

### 出口 IP 不是预期 ISP IP

Basic Mode 下，出口 IP 应该是 VPS 原生出口。

ISP Residential Exit Mode 下，出口 IP 应该是 SOCKS5 服务商提供的 IP。如果不是，请检查 SOCKS5 凭据和生成的 Xray 配置：

```bash
/usr/local/bin/xray run -test -config /etc/xray/config.json
```
