#!/bin/sh
# SnapDeploy xray node — VLESS + XHTTP (packet-up) over platform TLS :443
# Why XHTTP, not WebSocket: SnapDeploy docs state "WebSocket apps need Always-On ($12/mo) so connections are never dropped by sleep".
# XHTTP is the only transport that can work on the free tier.
# PORT is injected by SnapDeploy at runtime; container must listen on $PORT.
set -e
PORT_VAL=${PORT:-8080}
UUID_VAL=${UUID:-}
XHTTP_PATH_VAL=${XHTTP_PATH:-/snap-xhttp}
if [ -z "$UUID_VAL" ]; then echo "UUID missing" >&2; exit 1; fi
cat > /tmp/config.json <<EOF
{
  "log": {"loglevel": "warning"},
  "dns": {"servers": ["8.8.8.8", "1.1.1.1"], "queryStrategy": "UseIPv4"},
  "sniffing": {"enabled": true, "destOverride": ["http", "tls", "quic"]},
  "inbounds": [
    {
      "port": $PORT_VAL,
      "listen": "0.0.0.0",
      "protocol": "vless",
      "settings": {"clients": [{"id": "$UUID_VAL", "flow": ""}], "decryption": "none"},
      "streamSettings": {"network": "xhttp", "xhttpSettings": {"path": "$XHTTP_PATH_VAL", "mode": "packet-up"}}
    }
  ],
  "outbounds": [{"protocol": "freedom", "tag": "direct", "settings": {}}]
}
EOF
exec xray run -c /tmp/config.json
