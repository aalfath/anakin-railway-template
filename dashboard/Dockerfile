# syntax=docker/dockerfile:1
# AnakinScraper web dashboard (React), built from the upstream source at the pinned
# commit and served by nginx behind HTTP basic auth. nginx adds the API key to
# requests it forwards to the API over the private network, so the key never
# reaches the browser.
ARG ANAKIN_COMMIT=a842fc2f1fe5c22b80cd81e3f0760335ee21ed29

FROM node:22.23.4-bookworm-slim@sha256:5ec23b7c622b00547753bc6ffd78085dd868a68aeb41c8e0a1418f033e13d96d AS builder
ARG ANAKIN_COMMIT
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates git && rm -rf /var/lib/apt/lists/*
WORKDIR /src
RUN git init -q . \
 && git remote add origin https://github.com/Anakin-Inc/anakin.git \
 && git fetch -q --depth 1 origin "${ANAKIN_COMMIT}" \
 && git checkout -q FETCH_HEAD
WORKDIR /src/webapp
# The dashboard talks to /api on its own origin; nginx forwards that to the API.
RUN sed -i 's#http://localhost:8080/v1/scrape#https://YOUR-API-DOMAIN/v1/scrape#; s#Make sure the server is running on port 8080.#Check that the AnakinScraper service is running.#' src/pages/Dashboard.tsx \
 && npm ci --no-audit --no-fund \
 && npm run build

FROM nginx:1.30.7-alpine@sha256:caf4e1e032a20f9c3c5e28fc7f25ffd768ad8677b4975c54193075997b3a97e3
COPY --from=builder /src/webapp/dist /usr/share/nginx/html
COPY default.conf.template /etc/anakin-railway/default.conf.template
COPY 25-railway-dashboard.sh /docker-entrypoint.d/25-railway-dashboard.sh
RUN chmod 755 /docker-entrypoint.d/25-railway-dashboard.sh \
 && chmod 644 /etc/anakin-railway/default.conf.template \
 && rm -f /etc/nginx/conf.d/default.conf \
 && ln -s /tmp/anakin-railway/default.conf /etc/nginx/conf.d/default.conf
ENV PORT=8080
EXPOSE 8080
