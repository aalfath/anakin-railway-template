#!/bin/sh
# Writes the nginx site config (basic auth, /api proxy with the API key) before
# nginx starts. Fails closed: no password or API key, no start.
set -eu

PORT="${PORT:-8080}"
DASHBOARD_USERNAME="${DASHBOARD_USERNAME:-admin}"

if [ -z "${DASHBOARD_PASSWORD:-}" ]; then
  echo "25-railway-dashboard.sh: DASHBOARD_PASSWORD is empty; refusing to start without a login" >&2
  exit 1
fi
if [ -z "${ANAKIN_API_URL:-}" ] || [ -z "${ANAKIN_API_KEY:-}" ]; then
  echo "25-railway-dashboard.sh: ANAKIN_API_URL and ANAKIN_API_KEY are required" >&2
  exit 1
fi
case "$ANAKIN_API_KEY" in
  *[!A-Za-z0-9_-]*) echo "25-railway-dashboard.sh: ANAKIN_API_KEY may only contain letters, digits, - and _" >&2; exit 1 ;;
esac

# nginx re-resolves the API host through the container's DNS server, so a
# redeployed API (new private IP) is picked up without restarting the dashboard.
ns=$(awk '/^nameserver/ { print $2; exit }' /etc/resolv.conf)
case "$ns" in
  *:*) RESOLVER="[$ns]" ;;
  "") RESOLVER="127.0.0.11" ;;
  *) RESOLVER="$ns" ;;
esac

mkdir -p /tmp/anakin-railway
hash=$(printf '%s' "$DASHBOARD_PASSWORD" | mkpasswd -m sha512 -P 0)
case "$hash" in
  '$6$'*) ;;
  *) echo "25-railway-dashboard.sh: could not hash DASHBOARD_PASSWORD" >&2; exit 1 ;;
esac
printf '%s:%s\n' "$DASHBOARD_USERNAME" "$hash" > /tmp/anakin-railway/htpasswd
chmod 640 /tmp/anakin-railway/htpasswd
chgrp nginx /tmp/anakin-railway/htpasswd 2>/dev/null || true

API_URL="${ANAKIN_API_URL%/}"
sed -e "s|__PORT__|$PORT|g" \
    -e "s|__RESOLVER__|$RESOLVER|g" \
    -e "s|__API_URL__|$API_URL|g" \
    -e "s|__API_KEY__|$ANAKIN_API_KEY|g" \
    /etc/anakin-railway/default.conf.template > /tmp/anakin-railway/default.conf
chmod 640 /tmp/anakin-railway/default.conf
nginx -t -q
echo "25-railway-dashboard.sh: basic auth on for user $DASHBOARD_USERNAME, API at $API_URL, listening on $PORT"
