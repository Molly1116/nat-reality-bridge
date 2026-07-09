# Tested Environment

Language: [English](#english) | [中文](#中文)

## English

This page does not recommend any provider.

The entries below only record environments used while validating the NAT Reality Bridge deployment pattern. They do not imply long-term availability, stable pricing, inventory, routing quality, or IP quality.

## Entry Node Test Environment

Name: Test NAT VPS

Link: <https://dash.fuckip.me>

Description:

- Low-cost NAT VPS test environment.
- Used as an entry node for NAT port mapping and Reality inbound validation.
- Users should choose machines based on their own route, region, budget, and risk requirements.

## ISP Exit Test Environment

Name: ISP Residential SOCKS5

Link: <https://www.711proxy.com/signup?code=20560D>

Description:

- SOCKS5 ISP or residential exit test environment.
- Chosen during testing because it provides visibility into IP ranges.
- Users may choose other SOCKS5 providers according to their own requirements.

Other provider examples:

- Webshare
- Any SOCKS5 provider that supports authenticated proxy access and acceptable egress quality

## Notes

Provider conditions change frequently. Always test:

- NAT port forwarding
- TCP reachability
- Reality handshake compatibility
- SOCKS5 authentication
- Current exit IP
- Client-side route quality

## 中文

本页面不推荐任何供应商。

以下内容仅记录作者测试环境，不代表长期可用、价格稳定、库存充足、线路质量或 IP 质量保证。

## 入口机器测试环境

名称：Test NAT VPS

链接：<https://dash.fuckip.me>

说明：

- 低成本 NAT VPS 测试环境。
- 用于测试 NAT 端口映射和 Reality inbound。
- 用户应根据自己的线路、地区、预算和风险要求选择机器。

## ISP 出口测试环境

名称：ISP Residential SOCKS5

链接：<https://www.711proxy.com/signup?code=20560D>

说明：

- SOCKS5 ISP 或家宽出口测试环境。
- 测试时选择它的原因是支持查看 IP 段。
- 用户也可以根据自身需求选择其他 SOCKS5 供应商。

其他供应商示例：

- Webshare
- 任何支持认证代理访问且出口质量满足需求的 SOCKS5 供应商

## 注意事项

供应商条件经常变化。请始终自行测试：

- NAT 端口映射
- TCP 可达性
- Reality 握手兼容性
- SOCKS5 认证
- 当前出口 IP
- 客户端线路质量
