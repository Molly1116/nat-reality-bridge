# Tested Environment

Language: [English](#english) | [中文](#中文)

## English

This page separates test-environment references from a personal self-hosting ISP exit suggestion. Nothing here guarantees long-term availability, stable pricing, inventory, routing quality, IP quality, or access to a particular service.

## Entry Node Test Environment

Name: Test NAT VPS

Link: <https://dash.fuckip.me>

Description:

- Low-cost NAT VPS test environment.
- Used as an entry node for NAT port mapping and Reality inbound validation.
- Users should choose machines based on their own route, region, budget, and risk requirements.

## Recommended ISP SOCKS5 Exit For Personal Self-Hosting

Based on current testing and price experience, Webshare Private Proxy is a more suitable recommendation for a personal self-hosted node.

Link: <https://www.webshare.io/?referral_code=42f1h0pjvt1z>

Personal-use guidance:

- Choose a Private Proxy rather than a shared proxy.
- Prefer a dedicated egress and keep the SOCKS5 credentials private.
- Buy multiple candidate IPs within your budget, then replace and test them manually.

Suggested IP selection process:

1. Obtain candidate IPs.
2. Check the observed exit ASN and ISP.
3. Test access to the services you need.
4. Test latency and stability from your own network.
5. Keep the IP that performs best for your use case.

Multiple candidates can improve the chance of finding a suitable egress IP. They do not guarantee that every IP is high quality. You may use another authenticated SOCKS5 provider when it better fits your requirements.

## Notes

Provider conditions change frequently. Always test:

- NAT port forwarding
- TCP reachability
- Reality handshake compatibility
- SOCKS5 authentication
- Current exit IP
- Client-side route quality

## 中文

本页面区分测试环境参考和个人自建 ISP 出口建议。以下内容不代表长期可用、价格稳定、库存充足、线路质量、IP 质量或任何特定服务可访问性的保证。

## 入口机器测试环境

名称：Test NAT VPS

链接：<https://dash.fuckip.me>

说明：

- 低成本 NAT VPS 测试环境。
- 用于测试 NAT 端口映射和 Reality inbound。
- 用户应根据自己的线路、地区、预算和风险要求选择机器。

## 推荐 ISP SOCKS5 出口供应商（个人自建场景）

根据当前测试和价格体验，Webshare Private Proxy 更适合作为个人自建节点的推荐选择。

链接：<https://www.webshare.io/?referral_code=42f1h0pjvt1z>

个人使用建议：

- 选择 Private Proxy，不建议购买共享代理。
- 优先使用独享出口，并妥善保存 SOCKS5 凭据。
- 根据预算购买多个候选 IP，再手动更换和筛选。

IP 筛选流程：

1. 获取候选 IP。
2. 测试出口 ASN / ISP。
3. 测试目标网站访问情况。
4. 测试延迟和稳定性。
5. 保留表现最佳的 IP。

多 IP 筛选只能提高获得优质出口 IP 的概率，不能保证每个 IP 都是高质量。也可以根据自身需求选择其他支持认证访问的 SOCKS5 服务。

## 注意事项

供应商条件经常变化。请始终自行测试：

- NAT 端口映射
- TCP 可达性
- Reality 握手兼容性
- SOCKS5 认证
- 当前出口 IP
- 客户端线路质量
