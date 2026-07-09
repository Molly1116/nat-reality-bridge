# Architecture

## 中文

NAT Reality Bridge 采用入口/出口分离架构。入口节点运行在低资源 NAT VPS 上，负责客户端接入、Reality 握手和网络路径质量；出口节点通过 SOCKS5 outbound 提供最终公网 IP。

```text
Client
  |
  v
VLESS Reality TCP Vision
  |
  v
NAT VPS Entry Node
  |
  v
SOCKS5 Outbound
  |
  v
ISP Residential Exit
  |
  v
Internet
```

### 入口节点

入口节点通常是价格很低的 NAT VPS。它可能只有较少内存和有限公网端口，但如果线路质量好，就适合作为接入点。

入口节点职责：

- 监听内部 Xray 端口。
- 接收服务商 NAT 转发来的公网流量。
- 提供 VLESS Reality TCP Vision 入站。
- 将流量转发到指定 outbound。

### 出口节点

出口节点不是独立服务器，而是 SOCKS5 ISP 或住宅代理。它负责最终访问互联网时的出口 IP。

出口节点职责：

- 提供目标 IP 信誉。
- 承担最终公网出口。
- 与入口节点解耦，方便替换。

### 为什么适合低资源环境

该架构只需要一个 Xray 进程，不需要数据库、Docker、Web 面板或 Node.js。生产日志建议使用 `warning` 级别，减少内存和磁盘压力。

## English

NAT Reality Bridge uses a separated entry and exit architecture. The entry node runs on a low-resource NAT VPS and handles client connectivity, Reality handshake, and route quality. The exit node is provided by a SOCKS5 ISP or residential proxy and handles the final public egress IP.

### Entry Node

The entry node is usually a cheap NAT VPS. It may have very limited RAM and only a few forwarded public ports, but it can still be useful when the route quality is good.

Responsibilities:

- Listen on the internal Xray port.
- Receive provider NAT forwarded traffic.
- Serve VLESS Reality TCP Vision inbound.
- Route traffic to the configured outbound.

### Exit Node

The exit node is not managed by this project as a server. It is a SOCKS5 ISP or residential proxy endpoint.

Responsibilities:

- Provide egress IP reputation.
- Handle final Internet access.
- Stay replaceable without changing the entry node design.

### Low-Resource Fit

The design requires only one Xray process and avoids Docker, databases, web panels, and Node.js. Use `warning` log level in production to reduce overhead.
