# Changelog

## 2026-11-23: first version

- AnakinScraper `master` at `a842fc2f1fe5c22b80cd81e3f0760335ee21ed29` (2026-08-18): API-key auth, SSRF guard, Fiber patched to listen dual-stack for Railway's private network.
- Playwright 1.57.0 driver for the API taken from the official PyPI wheel (sha256-checked), because the playwright-go CDN no longer serves it.
- Camoufox 0.5.9 (browser 158.0.1-beta.41) with Playwright 1.57.0.
- Dashboard behind HTTP basic auth; nginx adds the API key server-side.
- Base images: golang 1.25.14-bookworm, debian bookworm-20261104-slim, python 3.11.18-slim-bookworm, node 22.23.4-bookworm-slim, nginx 1.30.7-alpine, all pinned by digest.
