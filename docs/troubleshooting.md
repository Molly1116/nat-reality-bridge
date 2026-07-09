# Troubleshooting

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
