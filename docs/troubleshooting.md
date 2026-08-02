# Troubleshooting

Language: [English](#english) | [中文](#中文)

## English

The following notes come from a real deployment process, with all production values removed.

### Reality EOF

Symptoms:

```text
Client imports the node but cannot connect.
Official Xray client reports EOF or connection reset.
```

Check order:

```bash
/usr/local/bin/xray run -test -config /etc/xray/config.json
ps -eo pid,comm,args | grep '[x]ray' || true
ss -tnlp
ss -tnp state established
```

For a full repository checkout, run `bash scripts/health-check.sh` to identify whether the host uses systemd, Supervisor, or no recognized backend before choosing backend-specific logs or restart commands.

For an external Reality failure, investigate in this order: public NAT mapping, entry IP or domain, Reality SNI, client URI parameters, public TCP reachability, internal listener, ISP SOCKS5 reachability, then the external client network.

Lessons:

- A reachable TCP port does not prove Reality handshake success.
- TLS fallback success does not prove authenticated Reality success.
- The `serverName` and `dest` pair can affect Reality behavior.

Known working profile:

```text
serverName: www.cloudflare.com
dest: www.cloudflare.com:443
spiderX: /
```

### NAT Port Issues

Debug method:

1. Hold an external TCP connection to the public port.
2. Run `ss -tnp state established` on the server.
3. Confirm the connection reaches Xray's internal listener.

If external TCP connects but the server sees nothing, check provider NAT mapping first.

### Parameter Compatibility

If several external ports all fail with the same EOF, but an isolated Reality instance with a different target works, the problem is more likely Reality parameter compatibility than NAT incompatibility.

### QR Code Generation

If `node.png` is missing, check whether `qrencode` is installed:

```bash
command -v qrencode
```

The installer can continue without QR code generation. The VLESS URI remains available in `/root/nat-reality-bridge/node.txt`.

### Outbound Test

From a full repository checkout, use:

```bash
bash scripts/test-outbound.sh
```

In ISP mode, this is a **Direct SOCKS5 Test**. A successful result proves SOCKS5 reachability and credentials only; it does not prove that a client completed a Reality handshake through Xray. Verify the final node from an external client.

If you downloaded only `install.sh`, this helper is not present. Inspect `/root/nat-reality-bridge/install-summary.txt`, validate the local config, and verify the node from an external client instead.

If the direct test fails, verify SOCKS5 host, port, username, password, provider reachability, and whether the provider allows the server IP to connect.

### Install Log

Installation logs are written to:

```text
/var/log/nat-reality-bridge-install.log
```

### Xray Configuration Test Failed

Problem:

The installer stops while validating the temporary Xray configuration. Xray download or checksum success alone does not mean a node was deployed.

Cause:

v1.5.0 used the historical path below, which current Xray format detection could not identify as JSON:

```text
Failed to get format of /etc/xray/config.json.tmp
```

v1.5.1 uses `/etc/xray/config.tmp.json` and rejects a temporary config path that does not end in `.json`.

Check commands:

```bash
# Standalone download
bash install.sh --status

# Full repository checkout
bash scripts/install.sh --status
```

Solution:

- Confirm the state reports `stage=CONFIG_TESTED`, `status=FAILED`, and `failure_reason=config_test_failed`; failure information is intentionally non-secret.
- Review `/var/log/nat-reality-bridge-install.log` without publishing its contents.
- The failed transaction removes its temporary config, unactivated `xray.new.*` binary, and newly created client files while preserving existing config, backups, install state, and install log.
- Download v1.5.1 or a later installer before starting a new protected transaction. Re-running `--restart-interrupted` with the old v1.5.0 script does not fix that script itself. Do not edit a temporary config to bypass validation.

### Installation Interrupted Or SSH Disconnected

Problem:

SSH disconnects during installation, or the terminal closes before the installer finishes.

Cause:

The installer may have already installed Xray, written partial output files, or completed successfully before the SSH session dropped.

Check commands:

```bash
# Standalone download
bash install.sh --status

# Full repository checkout
bash scripts/install.sh --status
ls -lah /root/nat-reality-bridge/
cat /root/nat-reality-bridge/install-summary.txt 2>/dev/null || true
```

Solution:

- Do not immediately run the installer again.
- Reconnect over SSH and inspect the non-secret transaction state first.
- If it is incomplete, inspect the displayed config and binary state, then run `bash install.sh --restart-interrupted` for a standalone download or `bash scripts/install.sh --restart-interrupted` from a repository checkout. Type `yes` only when you accept a new protected transaction and possible new node parameters.
- `--resume` remains a legacy alias for `--restart-interrupted`.
- If Xray is active and `node.txt` exists, import the node and test the client from an external network.
- If config files or summary files are missing, review `/var/log/nat-reality-bridge-install.log` before deciding whether to resume.

The state file records only stage, timestamp, service backend, backup path, status, and a non-secret failure reason summary. It does not store UUIDs, Reality private keys, SOCKS5 passwords, or VLESS URIs.

### Node Suddenly Unavailable

Problem:

The node worked before, but the client suddenly cannot connect.

Cause:

Common causes include a stopped Xray service, provider NAT mapping changes, temporary network issues, or an unavailable SOCKS5 exit.

Check commands:

```bash
# Full repository checkout: identify the selected backend first.
bash scripts/health-check.sh

# systemd backend only
systemctl status xray --no-pager
systemctl restart xray

# Supervisor backend only
supervisorctl status nat-reality-bridge-xray
supervisorctl restart nat-reality-bridge-xray

# Any backend
ss -tnlp | grep xray || true
cat /root/nat-reality-bridge/install-summary.txt 2>/dev/null || true
```

Solution:

- Confirm Xray is active after restart.
- Confirm Xray is listening on the internal port, usually `443`.
- Check the provider NAT port mapping still forwards the public port to internal `443/TCP`.
- In ISP Residential Exit Mode, verify the SOCKS5 exit is still reachable and credentials are still valid.

### systemd Command Exists But Service Management Fails

Problem:

`systemctl` exists, but it cannot connect to the system bus or cannot manage `xray`.

Cause:

Some NAT containers expose a systemd binary without a usable service manager.

Check command:

```bash
bash scripts/health-check.sh
```

Solution:

- The installer uses systemd only when PID 1 and the system bus are usable.
- If an already-running Supervisor is available, the installer uses its dedicated program instead.
- If neither backend is reliable, installation stops before config activation. Do not force a `systemctl restart` in that environment.

### Existing Advanced Xray Configuration

Problem:

```text
Detected existing advanced Xray configuration.
Installation aborted to avoid overwrite.
```

Cause:

The installer found multiple inbounds, multiple outbounds, or a structure it cannot safely identify as its supported single-node configuration. It also requires a valid root-only ownership marker at `/etc/nat-reality-bridge/managed.marker` before treating an existing Xray configuration as NAT Reality Bridge managed.

Solution:

- Do not remove the existing config to bypass this protection.
- Do not create an ownership marker manually to bypass protection. A deployment without a valid marker is preserved and requires manual review.
- Back up and review the configuration before any manual migration.
- This project does not manage or migrate multi-ISP configurations.

### Git Missing Or Apt Killed On 64 MB VPS

Symptoms:

```text
git: command not found
apt install git
Killed
```

Cause:

Minimal Debian NAT VPS images may not include Git. Git is not required by Xray at runtime. On 64 MB RAM machines, `apt` and package unpacking may need more temporary memory than the VPS has, so the kernel may terminate the process.

What to do:

- Treat 64 MB RAM NAT VPS as experimental.
- Prefer 128 MB RAM or above, with swap enabled.
- Avoid the Git clone workflow on extremely low-memory machines.
- Download the self-contained installer with `curl` or `wget` instead of installing Git.
- Use Git clone mainly for source review, development, forks, and contributions.

User installation workflow:

```bash
curl -fsSL https://raw.githubusercontent.com/Molly1116/nat-reality-bridge/main/scripts/install.sh -o install.sh
bash install.sh
```

Or:

```bash
wget https://raw.githubusercontent.com/Molly1116/nat-reality-bridge/main/scripts/install.sh -O install.sh
bash install.sh
```

v1.3.0 behavior:

- Below 80 MB RAM, the installer enters `EXTREME_LOW_RESOURCE` mode.
- QR code generation is skipped.
- ASN/Country lookup and non-essential outbound checks are skipped.
- Xray download, config generation, selected service-backend startup, and node file output are kept.

## 中文

以下问题来自真实部署过程，但已去除所有生产参数。

### Reality EOF

现象：

```text
客户端可以导入节点，但无法连接。
官方 Xray 客户端日志显示 EOF 或 connection reset。
```

检查顺序：

```bash
/usr/local/bin/xray run -test -config /etc/xray/config.json
ps -eo pid,comm,args | grep '[x]ray' || true
ss -tnlp
ss -tnp state established
```

完整仓库目录可先运行 `bash scripts/health-check.sh`，识别 systemd、Supervisor 或 unknown 后端后，再选择对应的日志和重启命令。

外部 Reality 连接失败时，按以下顺序排查：公网 NAT 映射、入口 IP 或域名、Reality SNI、客户端 URI 参数、公网 TCP 可达性、内部监听端口、ISP SOCKS5 可达性，最后检查外部客户端网络环境。

经验结论：

- TCP 端口可连接，不代表 Reality 握手成功。
- 普通 TLS fallback 可用，也不代表认证分支成功。
- Reality `serverName` 和 `dest` 组合可能影响握手。

已验证可行方案：

```text
serverName: www.cloudflare.com
dest: www.cloudflare.com:443
spiderX: /
```

### NAT 端口问题

排查方法：

1. 从外部保持一个 TCP 连接到公网端口。
2. 服务器上运行 `ss -tnp state established`。
3. 确认连接进入 Xray 内部监听端口。

如果外部 TCP 可连但服务器看不到连接，优先检查服务商端口映射。

### 参数兼容问题

如果多个外部端口都表现为同样 EOF，而隔离测试实例使用另一组 Reality 参数成功，说明问题更可能是 Reality 参数组合，而不是 NAT 环境本身。

### 二维码生成

如果缺少 `node.png`，先检查是否安装了 `qrencode`：

```bash
command -v qrencode
```

安装器可以在没有二维码的情况下继续完成部署。VLESS URI 仍然保存在 `/root/nat-reality-bridge/node.txt`。

### 出口检测

完整仓库目录中使用：

```bash
bash scripts/test-outbound.sh
```

ISP 模式中，这只是 **Direct SOCKS5 Test**。成功只代表 SOCKS5 地址和凭据可用，不代表客户端已经通过 Xray 完成 Reality 握手。请从外部客户端验证最终节点。

如果只下载了 `install.sh`，该辅助脚本并不存在。请查看 `/root/nat-reality-bridge/install-summary.txt`、验证本地配置，并从外部客户端验证节点。

如果直接测试失败，请检查 SOCKS5 地址、端口、用户名、密码、供应商可达性，以及供应商是否允许当前服务器 IP 连接。

### 安装日志

安装日志路径：

```text
/var/log/nat-reality-bridge-install.log
```

### Xray 配置测试失败

问题：

安装器在临时 Xray 配置校验阶段停止。Xray 下载或校验和成功，不代表节点已经部署成功。

原因：

v1.5.0 使用过以下历史路径，当前 Xray 格式识别无法把它当作 JSON：

```text
Failed to get format of /etc/xray/config.json.tmp
```

v1.5.1 使用 `/etc/xray/config.tmp.json`，并拒绝不以 `.json` 结尾的临时配置路径。

检查命令：

```bash
# 单文件下载
bash install.sh --status

# 完整仓库目录
bash scripts/install.sh --status
```

解决方法：

- 确认状态显示 `stage=CONFIG_TESTED`、`status=FAILED` 和 `failure_reason=config_test_failed`；失败信息刻意不包含敏感内容。
- 审查 `/var/log/nat-reality-bridge-install.log`，但不要公开日志内容。
- 失败事务会删除临时配置、未激活的 `xray.new.*` 二进制和新生成的客户端文件，同时保留已有配置、备份、安装状态和安装日志。
- 下载 v1.5.1 或更高版本安装器后再启动新的受保护安装事务；仅用旧版 v1.5.0 脚本执行 `--restart-interrupted` 无法修复旧脚本本身。不要编辑临时配置绕过校验。

### 安装中断或 SSH 断开

问题：

安装过程中 SSH 断开，或者终端在安装完成前关闭。

原因：

安装器可能已经完成 Xray 安装，也可能已经写入部分输出文件，甚至可能已经成功完成，只是 SSH 会话先断开了。

检查命令：

```bash
# 完整仓库目录：先识别服务后端
bash scripts/health-check.sh

# 任意安装方式
ls -lah /root/nat-reality-bridge/
cat /root/nat-reality-bridge/install-summary.txt 2>/dev/null || true
```

解决方法：

- 不要立即重新安装。
- 先重新登录 SSH，并执行上面的检查命令。
- 根据 health check 识别的 systemd 或 Supervisor 后端选择对应命令，不要因为 `systemctl` 存在就强行使用它。
- 如果 Xray 正在运行，且 `node.txt` 已存在，先导入节点并从外部网络测试客户端。
- 如果配置文件或总结文件缺失，先查看 `/var/log/nat-reality-bridge-install.log`，再判断是否需要重新执行安装器。

### systemd 命令存在但服务管理失败

问题：

`systemctl` 存在，但无法连接 system bus 或无法管理 `xray`。

原因：

部分 NAT 容器提供 systemd 命令，但没有可用的服务管理器。

检查命令：

```bash
bash scripts/health-check.sh
```

解决方法：

- 安装器只有在 PID 1 和 system bus 都可用时才使用 systemd。
- 如果已有正在运行的 Supervisor，安装器会使用专用 program。
- 两种后端都不可靠时，安装会在激活 config 前停止。不要在该环境中强行执行 `systemctl restart`。

### 已有高级 Xray 配置

问题：

```text
Detected existing advanced Xray configuration.
Installation aborted to avoid overwrite.
```

原因：

安装器发现多个 inbound、多个 outbound，或无法安全确认其为受支持的单节点结构。它还要求 `/etc/nat-reality-bridge/managed.marker` 中存在合法的、仅 root 可读的归属标记，才会把已有 Xray 配置视为本工具受管。

解决方法：

- 不要删除已有 config 来绕过保护。
- 不要手动创建归属标记来绕过保护。没有合法标记的部署会被保留，需要人工审查。
- 手动迁移前先备份并审查配置。
- 本项目不管理，也不迁移多 ISP 配置。

### 安装恢复

SSH 断开或安装意外停止后，不要立即重新安装。先检查状态。

单文件下载：

```bash
bash install.sh --status
```

完整仓库目录：

```bash
bash scripts/install.sh --status
```

如果状态显示未完成事务，先检查显示的 config 和 binary 状态。恢复会**重新启动一轮受保护安装事务**，不会从具体阶段继续，并且可能生成新的节点参数。

单文件下载：

```bash
bash install.sh --restart-interrupted
```

完整仓库目录：

```bash
bash scripts/install.sh --restart-interrupted
```

`--resume` 保留为兼容别名。

`install-state` 只保存阶段、时间、服务后端、备份路径、状态和非敏感失败原因摘要，不保存 UUID、Reality privateKey、SOCKS5 password 或 VLESS URI。

### 节点突然不可用

问题：

节点之前可以使用，但客户端突然无法连接。

原因：

常见原因包括 Xray 服务停止、服务商 NAT 映射变化、临时网络问题，或 SOCKS5 出口不可用。

检查命令：

```bash
# 完整仓库目录：先确认服务后端。
bash scripts/health-check.sh

# 仅 systemd 后端
systemctl status xray --no-pager
systemctl restart xray

# 仅 Supervisor 后端
supervisorctl status nat-reality-bridge-xray
supervisorctl restart nat-reality-bridge-xray

# 任意后端
ss -tnlp | grep xray || true
cat /root/nat-reality-bridge/install-summary.txt 2>/dev/null || true
```

解决方法：

- 确认重启后 Xray 处于 active。
- 确认 Xray 正在监听内部端口，通常是 `443`。
- 检查服务商 NAT 端口映射仍然将公网端口转发到内部 `443/TCP`。
- 如果使用 ISP Residential Exit Mode，确认 SOCKS5 出口仍可连接，账号密码仍有效。

### 64MB VPS 上 Git 缺失或 apt 被 Killed

现象：

```text
git: command not found
apt install git
Killed
```

原因：

Minimal Debian NAT VPS 默认可能没有 Git。Git 不是 Xray 运行依赖。在 64MB RAM 机器上，`apt` 和软件包解包阶段可能需要更多临时内存，系统可能会因为 OOM 终止安装进程。

处理建议：

- 将 64MB RAM NAT VPS 视为实验环境。
- 优先使用 128MB RAM 或更高配置，并启用 swap。
- 极低内存机器不建议使用 Git clone 工作流。
- 使用 `curl` 或 `wget` 下载自包含安装器，不要为了安装本项目而先安装 Git。
- Git clone 更适合源码审查、开发、fork 和贡献。

普通用户安装流程：

```bash
curl -fsSL https://raw.githubusercontent.com/Molly1116/nat-reality-bridge/main/scripts/install.sh -o install.sh
bash install.sh
```

或：

```bash
wget https://raw.githubusercontent.com/Molly1116/nat-reality-bridge/main/scripts/install.sh -O install.sh
bash install.sh
```

v1.3.0 行为：

- 低于 80MB RAM 时，安装器进入 `EXTREME_LOW_RESOURCE` 模式。
- 跳过二维码生成。
- 跳过 ASN/Country 查询和非必要出口检测。
- 保留 Xray 下载、配置生成、所选服务后端启动和节点文件输出。
