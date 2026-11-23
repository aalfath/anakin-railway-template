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
 && CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o /server ./cmd/server \
 && PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1 go run github.com/playwright-community/playwright-go/cmd/playwright@v0.5700.1 install

FROM debian:bookworm-20261104-slim@sha256:734a72b3d6142a71993b4bc580ca01d8ca687f77a2c422d96a961d3376b179bc
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates postgresql-client \
 && rm -rf /var/lib/apt/lists/* \
 && useradd -m appuser
COPY --from=builder --chown=appuser:appuser /root/.cache/ms-playwright-go/ /home/appuser/.cache/ms-playwright-go/
COPY --from=builder /server /usr/local/bin/server
COPY --from=builder /src/scripts/init-db.sql /app/init-db.sql
COPY start.sh /app/start.sh
RUN chmod 755 /app/start.sh
USER appuser
ENV PORT=8080
EXPOSE 8080
CMD ["/app/start.sh"]
