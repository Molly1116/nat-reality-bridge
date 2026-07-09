# Security Policy

## Reporting Security Issues

Do not open public issues containing credentials, private keys, live endpoints, or personal configurations.

For now, report security concerns by opening a minimal public issue that describes the affected area without secrets. A private contact channel can be arranged from there.

## Sensitive Data Rules

Do not commit:

- Passwords
- SSH credentials
- Reality private keys
- SOCKS5 proxy credentials
- Production UUIDs
- Live node URIs
- Personal Xray configs

If sensitive data is committed accidentally:

1. Remove it from the repository.
2. Rotate the exposed credential or key.
3. Treat the previous node link as compromised.

