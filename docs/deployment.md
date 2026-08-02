# Deployment

Language: [English](#english) | [中文](#中文)

First-time deployment users should start with:

- [Complete Deployment Guide](full-deployment-guide.md)
- [完整中文部署教程](full-deployment-guide.zh-CN.md)

This document is a technical deployment reference. It focuses on checks, configuration paths, installation behavior, and validation details without repeating the full beginner walkthrough.

## English

This document describes the generic deployment flow. Generate fresh values on every new server. Do not reuse production node parameters.

Since v1.2.0, `scripts/install.sh` is an interactive installer. It performs environment checks, asks for the deployment mode, generates fresh Reality values, tests a temporary JSON config, backs up the old config, and restarts Xray only after validation succeeds.

The temporary config used by Xray validation is `/etc/xray/config.tmp.json`; it must end in `.json`. If validation fails, the installation state is recorded as `FAILED` with a non-secret summary, and the transaction removes its temporary config, unactivated `xray.new.*` binary, and current uncommitted client output. Existing config, backups, state, and install log are preserved for review.

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
- a usable systemd service bus, or an existing working Supervisor instance.
- `curl` or `wget` is available.
- `unzip` and `sha256sum` are available.

Minimal Debian NAT VPS images may not include Git. Git is not a runtime dependency; it is only one way to fetch the project source code.

64 MB RAM NAT VPS instances are experimental. Xray-core itself is lightweight, but minimal containers can still fail during download, extraction, or package work. The installer does not install extra software automatically. If required tools or a reliable service manager are unavailable, it stops before activating a configuration. Use 128 MB RAM or above with swap as the recommended minimum.

Installer resource modes:

- `EXTREME_LOW_RESOURCE`: below 80 MB RAM. Keeps the core Xray download, config generation, verified service startup, and node file output path, but skips QR code generation, ASN/Country lookup, and non-essential outbound checks.
- `LOW_RESOURCE`: below 160 MB RAM. Continues the full install path and warns when swap is missing.
- `NORMAL`: 160 MB RAM or above.

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

For normal users, do not assume Git is available. `scripts/install.sh` is self-contained and can be downloaded directly from GitHub Raw.

User installation workflow:

```bash
curl -fsSL https://raw.githubusercontent.com/Molly1116/nat-reality-bridge/main/scripts/install.sh -o install.sh
```

Or:

```bash
wget https://raw.githubusercontent.com/Molly1116/nat-reality-bridge/main/scripts/install.sh -O install.sh
```

Review the entire script before running it:

```bash
sed -n '1,220p' install.sh
sed -n '221,520p' install.sh
sed -n '521,1120p' install.sh
```

Run the installer:

```bash
bash install.sh
```

If neither `curl` nor `wget` is available, download the GitHub repository ZIP from another machine, extract it, upload the project directory to the VPS, and run `bash scripts/install.sh`.

Developer workflow:

```bash
git clone https://github.com/Molly1116/nat-reality-bridge.git
cd nat-reality-bridge
```

The installer supports two modes:

- Basic Mode: VLESS Reality TCP Vision with VPS native exit.
- ISP Residential Exit Mode: VLESS Reality TCP Vision with SOCKS5 ISP or residential exit.

#### Service Backend Selection

The installer does not treat the presence of `systemctl` as proof that systemd works. It checks PID 1 and the system bus before selecting a backend:

- `SYSTEMD_AVAILABLE`: writes and manages `xray.service`.
- `SYSTEMD_UNAVAILABLE` with an existing Supervisor: creates the NAT Reality Bridge Supervisor program.
- No reliable manager: stops before activating config or replacing the active service.

Supervisor is never installed automatically. This protects low-memory NAT containers from package-installation OOM failures.

The installer also does not install Docker, Git, Python, Node.js, or a database.

#### Existing Configuration Protection

Before modifying an existing `/etc/xray/config.json`, the installer requires a valid, root-only ownership marker at `/etc/nat-reality-bridge/managed.marker`. The marker contains project metadata and a random install ID only; it never contains credentials or node identity.

Without a valid marker, the existing deployment is treated as user-managed and preserved. The installer does not migrate, overwrite, or remove it automatically. A marker-backed configuration must still match the supported single-node structure; multiple inbounds, multiple outbounds, or an unrecognized structure cause a safe abort:

```text
Detected existing advanced Xray configuration.
Installation aborted to avoid overwrite.
```

This release does not migrate or manage multi-ISP configurations.

#### Installation Recovery

An interrupted installation records a root-only state file at:

```text
/var/lib/nat-reality-bridge/install-state
```

Do not immediately reinstall after an SSH interruption. First inspect the state.

Standalone download:

```bash
bash install.sh --status
```

Full repository checkout:

```bash
bash scripts/install.sh --status
```

When the state is incomplete, the recovery entry point starts a **new protected installation transaction**. It does not resume individual stages and can generate new node parameters.

Standalone download:

```bash
bash install.sh --restart-interrupted
```

Full repository checkout:

```bash
bash scripts/install.sh --restart-interrupted
```

`--resume` is retained as a legacy alias for `--restart-interrupted`.

```bash
# Standalone download
bash install.sh --resume

# Full repository checkout
bash scripts/install.sh --resume
```

It starts a new protected transaction rather than resuming individual stages, and can generate new node parameters.

The state file records stage, timestamp, service backend, backup path, status, and a non-secret failure reason summary only. It does not store UUIDs, Reality private keys, SOCKS5 passwords, or VLESS URIs.

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

Temporary and activated Xray configuration files use `600 root:root` permissions.

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

The following helper commands are available only from a full repository checkout:

```bash
bash scripts/health-check.sh
bash scripts/test-outbound.sh
```

`health-check.sh` selects systemd, Supervisor, or unknown status according to the live host. `test-outbound.sh` performs a **Direct SOCKS5 Test** in ISP mode only. A passing direct test proves proxy reachability and credentials, not a successful Reality handshake.

In Basic Mode, the final client exit IP should match the VPS native exit. In ISP Residential Exit Mode, the final client exit IP should match the SOCKS5 ISP exit IP after authenticated Reality traffic has been verified from an external client. Standalone users can validate the local config with `/usr/local/bin/xray run -test -config /etc/xray/config.json` and must use an external client for final Reality verification. Completion requires config validation, an active selected backend, marker and client files, an internal listener, an external Reality connection, and a restart check. ISP Mode additionally requires a passing Direct SOCKS5 Test and matching intended ISP egress.

## 中文

首次部署用户建议先阅读：

- [完整中文部署教程](full-deployment-guide.zh-CN.md)
- [Complete Deployment Guide](full-deployment-guide.md)

本文档定位为技术部署参考，重点记录检查项、配置路径、安装行为和验证方式，不重复完整新手教程。

本文描述通用部署流程。所有值都应在新机器上重新生成，不要复用旧节点参数。

从 v1.2.0 开始，`scripts/install.sh` 是交互式安装器。它会执行环境检查、询问部署模式、生成新的 Reality 参数、测试临时 JSON 配置、备份旧配置，并且只在验证成功后重启 Xray。

供 Xray 校验使用的临时配置为 `/etc/xray/config.tmp.json`，必须以 `.json` 结尾。校验失败时，安装状态会记录为 `FAILED` 并写入非敏感失败摘要；本次事务会删除临时配置、未激活的 `xray.new.*` 二进制和本次未提交的客户端输出。已有配置、备份、状态文件和安装日志会保留以供审查。

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
- 可用的 systemd service bus，或已有且可工作的 Supervisor。
- `curl` 或 `wget` 可用。
- `unzip` 和 `sha256sum` 可用。

Minimal Debian NAT VPS 默认可能没有预装 Git。Git 不是运行依赖，只是获取项目源码的一种方式。

64MB RAM NAT VPS 属于实验环境。Xray-core 本身资源占用较低，但极简容器仍可能在下载、解压或软件包操作阶段失败。安装器不会自动安装额外软件；缺少必要工具或可靠服务管理器时会在激活配置前停止。建议最低使用 128MB RAM 并启用 swap。

安装器资源模式：

- `EXTREME_LOW_RESOURCE`：低于 80MB RAM。保留核心 Xray 下载、配置生成、已验证的服务启动和节点文件输出路径，但跳过可选二维码安装、ASN/Country 查询和非必要出口检测。
- `LOW_RESOURCE`：低于 160MB RAM。继续完整安装路径，并在缺少 swap 时提示。
- `NORMAL`：160MB RAM 或更高。

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

普通用户流程不应默认假设 Git 可用。`scripts/install.sh` 是自包含安装器，可以直接从 GitHub Raw 下载后运行。

普通用户安装流程：

```bash
curl -fsSL https://raw.githubusercontent.com/Molly1116/nat-reality-bridge/main/scripts/install.sh -o install.sh
```

或：

```bash
wget https://raw.githubusercontent.com/Molly1116/nat-reality-bridge/main/scripts/install.sh -O install.sh
```

执行前先完整审查脚本：

```bash
sed -n '1,220p' install.sh
sed -n '221,520p' install.sh
sed -n '521,1120p' install.sh
```

运行安装器：

```bash
bash install.sh
```

如果 VPS 上既没有 `curl` 也没有 `wget`，可以在其他机器下载 GitHub 仓库 ZIP，解压后上传项目目录到 VPS，再执行 `bash scripts/install.sh`。

开发者流程：

```bash
git clone https://github.com/Molly1116/nat-reality-bridge.git
cd nat-reality-bridge
```

安装器支持两种模式：

- Basic Mode：VLESS Reality TCP Vision，使用 VPS 原生出口。
- ISP Residential Exit Mode：VLESS Reality TCP Vision，使用 SOCKS5 ISP 或家宽出口。

#### 服务后端选择

安装器不会因为存在 `systemctl` 就假定 systemd 可用。它会检查 PID 1 和 system bus，再选择后端：

- `SYSTEMD_AVAILABLE`：写入并管理 `xray.service`。
- `SYSTEMD_UNAVAILABLE` 且已有 Supervisor：创建 NAT Reality Bridge 的 Supervisor program。
- 没有可靠服务管理器：在激活配置或替换活动服务前停止。

安装器绝不自动安装 Supervisor，避免低内存 NAT 容器在软件包安装阶段 OOM。

安装器也不会自动安装 Docker、Git、Python、Node.js 或数据库。

#### 已有配置保护

修改已有 `/etc/xray/config.json` 前，安装器要求 `/etc/nat-reality-bridge/managed.marker` 中存在合法的、仅 root 可读的归属标记。标记只记录项目元数据和随机 install ID，不包含连接凭据或节点身份。

没有合法标记时，已有部署会被视为用户自行管理并被保留；安装器不会自动迁移、覆盖或删除。对于有标记的配置，仍必须符合受支持的单节点结构；发现多个 inbound、多个 outbound 或未知结构时会安全中止：

```text
Detected existing advanced Xray configuration.
Installation aborted to avoid overwrite.
```

本版本不迁移，也不管理多 ISP 配置。

#### 安装恢复

安装中断时会记录 root-only 状态文件：

```text
/var/lib/nat-reality-bridge/install-state
```

SSH 中断后不要立刻重新安装，先检查状态。

单文件下载：

```bash
bash install.sh --status
```

完整仓库目录：

```bash
bash scripts/install.sh --status
```

状态显示未完成时，恢复入口会**重新启动一轮受保护安装事务**，不会从具体阶段继续，并且可能生成新的节点参数。

单文件下载：

```bash
bash install.sh --restart-interrupted
```

完整仓库目录：

```bash
bash scripts/install.sh --restart-interrupted
```

`--resume` 保留为 `--restart-interrupted` 的兼容别名。

```bash
# 单文件下载
bash install.sh --resume

# 完整仓库目录
bash scripts/install.sh --resume
```

它会启动新的受保护事务，而不是从具体阶段继续，可能生成新的节点参数。

状态文件只记录阶段、时间、服务后端、备份路径、状态和非敏感失败原因摘要，不保存 UUID、Reality privateKey、SOCKS5 password 或 VLESS URI。

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

临时和激活后的 Xray 配置均使用 `600 root:root` 权限。

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

以下辅助命令只适用于完整仓库目录：

```bash
bash scripts/health-check.sh
bash scripts/test-outbound.sh
```

`health-check.sh` 会根据实际主机选择 systemd、Supervisor 或 unknown 状态。ISP 模式中，`test-outbound.sh` 只执行 **Direct SOCKS5 Test**。直接测试通过只说明代理地址和凭据可用，不代表 Reality 握手成功。

Basic Mode 下，最终客户端出口 IP 应等于 VPS 原生出口。ISP Residential Exit Mode 下，只有从外部客户端完成认证 Reality 流量验证后，最终出口 IP 才应等于 SOCKS5 ISP 出口 IP。单文件用户可以通过 `/usr/local/bin/xray run -test -config /etc/xray/config.json` 验证本地配置，并必须从外部客户端完成最终 Reality 验证。部署完成还需要配置测试通过、所选服务后端 active、marker 和客户端文件已生成、内部端口正在监听、外部 Reality 连接成功，以及重启后仍可用。ISP Mode 还需 Direct SOCKS5 Test 通过并确认使用预期 ISP 出口。
