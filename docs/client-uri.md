# Client URI

## 中文

v2rayNG、Karing 和兼容客户端可以使用 VLESS URI 导入节点。

模板：

```text
vless://UUID@PUBLIC_HOST:PUBLIC_PORT?encryption=none&flow=xtls-rprx-vision&security=reality&sni=www.cloudflare.com&fp=chrome&pbk=PUBLIC_KEY&sid=SHORT_ID&type=tcp&headerType=none&spx=%2F#NODE_NAME
```

参数说明：

- `UUID`: VLESS 用户 ID，每台机器重新生成。
- `PUBLIC_HOST`: NAT VPS 的公网入口地址或域名。
- `PUBLIC_PORT`: 服务商映射的外部端口。
- `flow`: 固定为 `xtls-rprx-vision`。
- `security`: 固定为 `reality`。
- `sni`: Reality serverName，本模板使用 `www.cloudflare.com`。
- `fp`: 客户端指纹，建议 `chrome`。
- `pbk`: Reality public key，只给客户端使用。
- `sid`: Reality short ID。
- `type`: `tcp`。
- `spx`: spiderX，模板使用 `/`，URI 中编码为 `%2F`。

不要把 Reality `privateKey` 写入客户端 URI。

## English

v2rayNG, Karing, and compatible clients can import nodes using a VLESS URI.

Template:

```text
vless://UUID@PUBLIC_HOST:PUBLIC_PORT?encryption=none&flow=xtls-rprx-vision&security=reality&sni=www.cloudflare.com&fp=chrome&pbk=PUBLIC_KEY&sid=SHORT_ID&type=tcp&headerType=none&spx=%2F#NODE_NAME
```

Parameter notes:

- `UUID`: VLESS user ID. Generate a new one per server.
- `PUBLIC_HOST`: Public NAT entry address or domain.
- `PUBLIC_PORT`: Provider-side forwarded port.
- `flow`: Use `xtls-rprx-vision`.
- `security`: Use `reality`.
- `sni`: Reality serverName, `www.cloudflare.com` in this template.
- `fp`: Client fingerprint, usually `chrome`.
- `pbk`: Reality public key for clients.
- `sid`: Reality short ID.
- `type`: `tcp`.
- `spx`: spiderX. `/` is encoded as `%2F`.

Never include the Reality `privateKey` in client configuration.
