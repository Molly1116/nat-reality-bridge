# Changelog

## v1.3.1

- Document the normal user installation workflow without requiring Git.
- Add GitHub Raw `curl` and `wget` installer download examples.
- Clarify that `git clone` is mainly for source review, development, forks, and contributions.
- Document the repository ZIP fallback when neither `curl` nor `wget` is available.

## v1.3.0

- Add EXTREME_LOW_RESOURCE, LOW_RESOURCE, and NORMAL installer modes.
- Support curl or wget as the Xray-core download tool.
- Remove automatic apt installation for optional QR code dependency.
- Skip non-essential outbound metadata checks on 64MB-class VPS nodes.
- Improve documentation for Git-free, low-resource deployment paths.

## v1.2.2

- Clarify developer workflow and user installation workflow.
- Add low-resource NAT VPS deployment notes.
- Add 128MB RAM recommendation.
- Document 64MB extreme environment limitations.
- Improve first-time deployment documentation.

## v1.2.1

- Restore example test environment documentation.
- Add reproducible deployment references.
- Improve README clarity.

## v1.2.0

- Added beginner-friendly installation completion summary.
- Added terminal and PNG QR code generation.
- Added `/root/nat-reality-bridge/` client output directory.
- Added `install-summary.txt` and install logging.
- Added outbound test helper.
- Added uninstall helper.
- Added safe update helper without automatic Xray-core replacement.
- Added beginner user guide.

## v1.1.0

- Added interactive installer.
- Added Basic deployment mode with VPS native exit.
- Added ISP Residential Exit mode with SOCKS5 outbound.
- Added automatic VLESS URI generation.
- Added health check tools.
- Added tested environment documentation.

## v1.0.0

- Initial release.
- Added NAT VPS entry and ISP residential exit architecture.
- Added Xray Reality TCP Vision template.
- Added SOCKS5 outbound routing model.
- Added bilingual documentation.
- Added interactive installation script draft.
- Added security and contribution guidelines.
