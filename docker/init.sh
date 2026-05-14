#!/bin/bash
set -e

echo "🚀 Initializing Obelisk PN Docker Environment..."

# Create necessary directories
mkdir -p xray nginx/html
chown -R nobody:nogroup xray

# Check if docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker and Docker Compose."
    exit 1
fi

echo "🔑 Generating Xray keys..."
UUID=$(docker run --rm teddysun/xray xray uuid)
KEYS=$(docker run --rm teddysun/xray xray x25519)
PRIVATE_KEY=$(echo "$KEYS" | grep -i "PrivateKey" | awk '{print $3}' | tr -d '\r')
PUBLIC_KEY=$(echo "$KEYS"  | grep -i "PublicKey"  | awk '{print $3}' | tr -d '\r')
SHORT_ID=$(openssl rand -hex 4 2>/dev/null || cat /proc/sys/kernel/random/uuid | tr -d '-' | head -c 8)

echo "⚙️ Generating config.json..."
cat > xray/config.json << EOF
{
  "log": {
    "loglevel": "none"
  },
  "inbounds": [
    {
      "listen": "0.0.0.0",
      "port": 10443,
      "protocol": "vless",
      "settings": {
        "clients": [{"id": "$UUID", "flow": "xtls-rprx-vision"}],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "show": false,
          "dest": "yahoo.com:443",
          "serverNames": ["yahoo.com"],
          "privateKey": "$PRIVATE_KEY",
          "shortIds": ["$SHORT_ID"]
        },
        "tcpSettings": {
          "acceptProxyProtocol": true,
          "header": {"type": "none"}
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls", "quic"]
      }
    }
  ],
  "outbounds": [
    {"protocol": "freedom", "tag": "direct"},
    {"protocol": "blackhole", "tag": "block"}
  ]
}
EOF

echo "✅ Config generated."
echo ""
echo "====================================="
echo "🔑 CONNECTION DETAILS"
echo "====================================="
echo "UUID: $UUID"
echo "Public Key: $PUBLIC_KEY"
echo "Short ID: $SHORT_ID"
echo "SNI: yahoo.com"
echo "====================================="
echo ""
echo "🐳 Starting containers..."
docker compose up -d || docker-compose up -d

echo "✅ Obelisk PN is running!"
