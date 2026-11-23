# AnakinScraper on Railway

A Railway template for [AnakinScraper](https://github.com/Anakin-Inc/anakin), the open-source web scraping API from Anakin (AGPL-3.0). It turns any web page into clean markdown, HTML or structured JSON, with an HTTP fetcher, a Camoufox anti-detect browser fallback, per-domain rules and proxy auto-selection.

## What it deploys

| Service | Built from | Public | Notes |
|---|---|---|---|
| **AnakinScraper** | `api/` (Go API server) | yes, needs `API_KEY` | REST API on `PORT` 8080, health path `/health` |
| **Dashboard** | `dashboard/` (React UI on nginx) | yes, HTTP basic auth | Forwards `/api` to the API over the private network and adds the API key there, so the key never reaches the browser |
| **Browser** | `browser/` (Camoufox server) | no | Playwright WebSocket on port 9222, private network only |
| **Postgres** | Railway Postgres | no | Jobs, results, domain configs and proxy scores (on a volume) |

**Version:** AnakinScraper `master` at commit [`a842fc2`](https://github.com/Anakin-Inc/anakin/commit/a842fc2f1fe5c22b80cd81e3f0760335ee21ed29) (2026-08-18). Upstream publishes no container image, and its only release, v0.1.1 (2026-03-23), predates the API-key auth and the SSRF guard, so the Dockerfiles build that pinned commit. Camoufox 0.5.9 (browser build 158.0.1-beta.41) with Playwright 1.57.0. Base images are pinned by version and digest.

## Variables

| Service | Variable | Default | Meaning |
|---|---|---|---|
| AnakinScraper | `API_KEY` | generated | Key for every `/v1` route (`X-API-Key` header or `Authorization: Bearer`). The server refuses to start without it. |
| AnakinScraper | `DATABASE_URL` | `${{Postgres.DATABASE_URL}}` | Postgres on the private network. |
| AnakinScraper | `BROWSER_WS_URL` | `ws://${{Browser.RAILWAY_PRIVATE_DOMAIN}}:9222/camoufox` | The Camoufox browser service. |
| AnakinScraper | `PORT` | `8080` | Port the API listens on. |
| Dashboard | `DASHBOARD_USERNAME` | `admin` | Basic-auth user. |
| Dashboard | `DASHBOARD_PASSWORD` | generated | Basic-auth password. Read it in the Dashboard service's Variables tab. |
| Dashboard | `ANAKIN_API_URL`, `ANAKIN_API_KEY` | references | Where the dashboard forwards API calls, and the key it adds. |
| Browser | `PORT`, `WS_PATH` | `9222`, `camoufox` | The WebSocket the API connects to. |

Optional, set on the AnakinScraper service when you need them: `GEMINI_API_KEY` (structured JSON extraction with `generateJson`), `PROXY_URL` or `PROXY_URLS` (proxy pool), `ANAKIN_API_KEY` (hosted anakin.io fallback), `WORKER_POOL_SIZE` (default 5), `TELEMETRY=off` (upstream sends anonymous usage counts by default, see its [TELEMETRY.md](https://github.com/Anakin-Inc/anakin/blob/master/TELEMETRY.md)).

## Use it

```bash
curl -X POST https://YOUR-API-DOMAIN/v1/scrape \
  -H "X-API-Key: YOUR-API-KEY" \
  -H "Content-Type: application/json" \
  -d '{"url": "https://example.com"}'
```

Add `"useBrowser": true` to render JavaScript-heavy pages in Camoufox. The API reference is upstream's [docs/API.md](https://github.com/Anakin-Inc/anakin/blob/master/docs/API.md).

## Updates

Each service builds from this repo. When a new upstream commit or base image is tested, it is merged to `main` with an entry in [CHANGELOG.md](CHANGELOG.md), and Railway offers the update to everyone who deployed the template. Read the changelog before you apply it: breaking changes are listed first. The database schema is applied on every start with `CREATE ... IF NOT EXISTS`, so data stays in place.

## License

The wrapper files in this repo are MIT. AnakinScraper itself is AGPL-3.0: if you modify it and offer it to others over a network, you must publish your changes.
