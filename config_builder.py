import json

class ObeliskConfigGenerator:
    @staticmethod
    def create_client_json(uuid, public_key, short_id, host, port=443):
        sni = "yahoo.com"
        
        direct_domains = [
            r"regexp:.*\.ru$",
            "domain:yandex.net",
            "domain:vk.com",
            "domain:gosuslugi.ru",
            "domain:sberbank.ru"
        ]
        
        proxy_domains = [
            "geosite:youtube",
            "geosite:github",
            "geosite:openai",
            "geosite:instagram",
            "geosite:twitter"
        ]

        dns_servers = [
            {
                "address": "https://dns.yandex.ru/dns-query",
                "domains": [r"regexp:.*\.ru$"],
                "skipFallback": True
            },
            "https://dns.google/dns-query",
            "8.8.8.8"
        ]

        config = {
            "dns": {
                "servers": dns_servers,
                "queryStrategy": "UseIPv4"
            },
            "inbounds": [
                {
                    "port": 10808,
                    "protocol": "socks",
                    "settings": {"udp": True},
                    "tag": "socks"
                }
            ],
            "outbounds": [
                {
                    "protocol": "vless",
                    "settings": {
                        "vnext": [{
                            "address": host,
                            "port": port,
                            "users": [{"id": uuid, "flow": "xtls-rprx-vision", "encryption": "none"}]
                        }]
                    },
                    "streamSettings": {
                        "network": "tcp",
                        "security": "reality",
                        "realitySettings": {
                            "publicKey": public_key,
                            "serverName": sni,
                            "shortId": short_id,
                            "fingerprint": "chrome"
                        },
                        "sockopt": {
                            "tcpFastOpen": True,
                            "tcpKeepAliveIdle": 100
                        }
                    },
                    "tag": "proxy"
                },
                {"protocol": "freedom", "tag": "direct"},
                {"protocol": "blackhole", "tag": "block"}
            ],
            "routing": {
                "domainStrategy": "IPIfNonMatch",
                "rules": [
                    {"type": "field", "domain": direct_domains, "outboundTag": "direct"},
                    {"type": "field", "domain": proxy_domains, "outboundTag": "proxy"},
                    {"type": "field", "ip": ["geoip:ru"], "outboundTag": "direct"}
                ]
            }
        }
        return config

if __name__ == "__main__":
    example = ObeliskConfigGenerator.create_client_json(
        "your-uuid-here", 
        "your-public-key", 
        "shortid", 
        "your.server.com"
    )
    print(json.dumps(example, indent=2))
