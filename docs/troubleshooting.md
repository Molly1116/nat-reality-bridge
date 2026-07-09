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
systemctl is-active xray
ss -tnlp
ss -tnp state established
journalctl -u xray --no-pager -n 80
```

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

Use:

```bash
bash scripts/test-outbound.sh
```

If ISP mode fails, verify SOCKS5 host, port, username, password, provider reachability, and whether the provider allows the server IP to connect.

### Install Log

Installation logs are written to:

```text
/var/log/nat-reality-bridge-install.log
```

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
- Optional QR dependency installation is skipped.
- ASN/Country lookup and non-essential outbound checks are skipped.
- Xray download, config generation, systemd startup, and node file output are kept.

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
systemctl is-active xray
ss -tnlp
ss -tnp state established
journalctl -u xray --no-pager -n 80
```

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

使用：

```bash
bash scripts/test-outbound.sh
```

如果 ISP 模式失败，请检查 SOCKS5 地址、端口、用户名、密码、供应商可达性，以及供应商是否允许当前服务器 IP 连接。

### 安装日志

安装日志路径：

```text
/var/log/nat-reality-bridge-install.log
```

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
- 跳过可选二维码依赖安装。
- 跳过 ASN/Country 查询和非必要出口检测。
- 保留 Xray 下载、配置生成、systemd 启动和节点文件输出。
