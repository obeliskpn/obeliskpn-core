#!/bin/bash

set -e

apt update && apt upgrade -y
apt install -y curl wget ufw net-tools python3 openssl nginx

bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

cat >> /etc/sysctl.conf << 'EOF'
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
net.core.rmem_max=134217728
net.core.wmem_max=134217728
net.ipv4.tcp_rmem=4096 87380 134217728
net.ipv4.tcp_wmem=4096 65536 134217728
net.core.somaxconn=16384
net.ipv4.tcp_max_syn_backlog=16384
net.ipv4.tcp_slow_start_after_idle=0
net.ipv4.tcp_fastopen=3
net.ipv4.tcp_tw_reuse=1
net.ipv4.tcp_fin_timeout=20
net.ipv4.tcp_keepalive_time=600
net.ipv4.tcp_mtu_probing=1
net.ipv4.tcp_syncookies=1
net.ipv4.tcp_max_orphans=32768
EOF
sysctl -p

ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

mkdir -p /var/log/xray
chown nobody:nogroup /var/log/xray

UUID=$(xray uuid)
KEYS_OUTPUT=$(xray x25519)
PRIVATE_KEY=$(echo "$KEYS_OUTPUT" | grep -i "PrivateKey" | awk -F': ' '{print $2}' | tr -d ' \r\n')
PUBLIC_KEY=$(echo "$KEYS_OUTPUT"  | grep -i "PublicKey"  | awk -F': ' '{print $2}' | tr -d ' \r\n')
SHORT_ID=$(openssl rand -hex 4)

cat > /usr/local/etc/xray/config.json << EOF
{
  "log": {
    "loglevel": "warning",
    "access": "/var/log/xray/access.log",
    "error": "/var/log/xray/error.log"
  },
  "inbounds": [
    {
      "listen": "127.0.0.1",
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
  ],
  "routing": {
    "domainStrategy": "IPIfNonMatch",
    "rules": [
      {"type": "field", "ip": ["geoip:private"], "outboundTag": "block"},
      {"type": "field", "protocol": ["bittorrent"], "outboundTag": "block"}
    ]
  }
}
EOF

rm -f /etc/nginx/sites-enabled/default
cat > /etc/nginx/stream-vpn.conf << 'NGINX_CONF'
stream {
    server {
        listen 443 so_keepalive=on;
        proxy_pass 127.0.0.1:10443;
        proxy_protocol on;
        proxy_timeout 1h;
        proxy_connect_timeout 10s;
        tcp_nodelay on;
    }
}
NGINX_CONF

if ! grep -q "include /etc/nginx/stream-vpn.conf" /etc/nginx/nginx.conf; then
    echo "include /etc/nginx/stream-vpn.conf;" >> /etc/nginx/nginx.conf
fi

cat > /etc/nginx/sites-available/vpn-stub << 'STUB_CONF'
server {
    listen 80 default_server;
    server_name _;
    server_tokens off;
    if ($request_method = CONNECT) {
        return 405;
    }
    location / {
        default_type text/html;
        return 200 '<!DOCTYPE html><html><body><h1>Welcome</h1><p>Server operational.</p></body></html>';
    }
}
STUB_CONF
ln -sf /etc/nginx/sites-available/vpn-stub /etc/nginx/sites-enabled/vpn-stub

systemctl restart nginx
systemctl enable xray
systemctl restart xray

echo "Setup complete."
echo "UUID: $UUID"
echo "Public Key: $PUBLIC_KEY"
echo "Short ID: $SHORT_ID"
