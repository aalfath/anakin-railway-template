# syntax=docker/dockerfile:1
# Camoufox anti-detect browser (Firefox) served over a Playwright WebSocket for the
# AnakinScraper API. Runs upstream's browser-service/server.py at the pinned commit.
# Private only: it has no public domain and must never get one.
ARG ANAKIN_COMMIT=a842fc2f1fe5c22b80cd81e3f0760335ee21ed29

FROM python:3.11.18-slim-bookworm@sha256:a83ba18aef0f865b1a4a611c2cf460fe446f2795673bbb9fe43be570439e3b39
ARG ANAKIN_COMMIT
WORKDIR /app
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl \
 && curl -fsSL -o server.py "https://raw.githubusercontent.com/Anakin-Inc/anakin/${ANAKIN_COMMIT}/browser-service/server.py" \
 && grep -q 'def run_browser' server.py \
 && rm -rf /var/lib/apt/lists/*
# Upstream pins playwright 1.57.0, which must match the API's playwright-go driver.
# camoufox 0.5.9 pairs with browser build v158.0.1-beta.41.
RUN pip install --no-cache-dir "playwright==1.57.0" "camoufox[geoip]==0.5.9" \
 && playwright install-deps firefox \
 && python3 -m camoufox fetch \
 && rm -rf /var/lib/apt/lists/* /root/.cache/pip
ENV PORT=9222 WS_PATH=camoufox HEADLESS=true HEALTH_CHECK_PORT=8080
EXPOSE 9222
CMD ["python", "server.py"]
