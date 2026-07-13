# Changelog

## v1.4.2

### Deployment Experience Improvements

- Clarify NAT VPS Entry Node and ISP Residential Exit separation.
- Add Linux password input notes.
- Explain installation confirmation behavior.
- Add interrupted installation troubleshooting.
- Add node availability troubleshooting.
- 中文同步：补充入口节点/出口节点区别、Linux 密码输入说明、安装确认行为、安装中断排查和节点突然不可用排查。

## v1.4.1

Documentation structure cleanup

- Move provider-specific test environment references out of README.
- Add a dedicated Chinese complete deployment guide.
- Reformat README features into professional grouped sections.
- Clarify README as project overview and entry point.
- Preserve historical changelog entries.

## v1.4.0

Documentation restructure for first-time deployment success

- Simplify README as project overview and entry page.
- Add complete deployment guide.
- Add full first-time deployment command flow.
- Clarify standalone installer workflow and full repository workflow.
- Improve service-check guidance for users without helper scripts.

## v1.3.1

- Document the normal user installation workflow without requiring Git.
- Add GitHub Raw `curl` and `wget` installer download examples.
- Clarify that `git clone` is mainly for source review, development, forks, and contributions.
- Document the repository ZIP fallback when neither `curl` nor `wget` is available.

## v1.3.0

Ultra low resource optimization

- Add RAM and swap detection.
- Add EXTREME_LOW_RESOURCE and LOW_RESOURCE modes.
- Add curl/wget fallback for downloading.
- Remove automatic installation of heavy dependencies.
- Optimize installation behavior for 64MB and 128MB NAT VPS.
- Keep Xray Reality and SOCKS5 outbound architecture unchanged.

## v1.2.2

Improve first-time deployment documentation

- Clarify user installation workflow.
- Explain that Git is a developer workflow tool, not a runtime dependency.
- Add low-resource NAT VPS deployment notes.
- Add 128MB RAM recommendation and 64MB experimental environment notes.
- Improve documentation consistency across README and user guides.

## v1.2.1

Restore test environment documentation

- Restore Example Test Environment documentation.
- Add reproducible deployment references.
- Clarify that test environments are for architecture verification, not vendor recommendation.
- Restore NAT VPS Entry Node and ISP Residential Exit examples.

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
