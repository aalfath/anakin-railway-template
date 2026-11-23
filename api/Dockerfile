# syntax=docker/dockerfile:1
# AnakinScraper API server (Go), built from the upstream source at a pinned commit.
# Upstream publishes no container image, and its only release (v0.1.1) predates the
# API-key auth and SSRF guard, so this builds master at the commit below.
# To update: change ANAKIN_COMMIT here and in ../browser and ../dashboard, and add a CHANGELOG entry.
ARG ANAKIN_COMMIT=a842fc2f1fe5c22b80cd81e3f0760335ee21ed29

FROM golang:1.25.14-bookworm@sha256:3b4a11519ad929d1e1d261a12cff056f0c85b735253d7d861346b9c6f8b36437 AS builder
ARG ANAKIN_COMMIT
WORKDIR /src
RUN git init -q . \
 && git remote add origin https://github.com/Anakin-Inc/anakin.git \
 && git fetch -q --depth 1 origin "${ANAKIN_COMMIT}" \
 && git checkout -q FETCH_HEAD
WORKDIR /src/server
# Fiber v2 listens on IPv4 only by default; "tcp" is dual-stack, so the Dashboard
# can reach the API over Railway's private network.
RUN sed -i 's/app := fiber.New(fiber.Config{/app := fiber.New(fiber.Config{\n\t\tNetwork: "tcp",/' cmd/server/main.go \
 && grep -q 'Network: "tcp"' cmd/server/main.go \
 && go mod download \
 && CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o /server ./cmd/server

# playwright-go v0.5700.1 needs the Playwright 1.57.0 driver (node + cli.js). Its CDN
# (playwright.azureedge.net) now answers 404, so take the identical driver from the
# official playwright 1.57.0 wheel on PyPI, checked by sha256.
FROM python:3.11.18-slim-bookworm@sha256:a83ba18aef0f865b1a4a611c2cf460fe446f2795673bbb9fe43be570439e3b39 AS driver
ARG PW_WHEEL_URL=https://files.pythonhosted.org/packages/56/61/3a803cb5ae0321715bfd5247ea871d25b32c8f372aeb70550a90c5f586df/playwright-1.57.0-py3-none-manylinux1_x86_64.whl
ARG PW_WHEEL_SHA256=284ed5a706b7c389a06caa431b2f0ba9ac4130113c3a779767dda758c2497bb1
COPY fetch-driver.py /tmp/fetch-driver.py
RUN python3 /tmp/fetch-driver.py
RUN /driver/1.57.0/node /driver/1.57.0/package/cli.js --version | grep -q 1.57.0

FROM debian:bookworm-20261104-slim@sha256:734a72b3d6142a71993b4bc580ca01d8ca687f77a2c422d96a961d3376b179bc
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates postgresql-client \
 && rm -rf /var/lib/apt/lists/* \
 && useradd -m appuser
COPY --from=driver --chown=appuser:appuser /driver/ /home/appuser/.cache/ms-playwright-go/
COPY --from=builder /server /usr/local/bin/server
COPY --from=builder /src/scripts/init-db.sql /app/init-db.sql
COPY start.sh /app/start.sh
RUN chmod 755 /app/start.sh
USER appuser
ENV PORT=8080
EXPOSE 8080
CMD ["/app/start.sh"]
