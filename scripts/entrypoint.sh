#!/bin/bash
set -e

cp -a /opt/preinstall/. /home/ 2>/dev/null || true

mkdir -p /home/go ~/.openclaw

cat > ~/.openclaw/openclaw.json << 'EOF'
{
  "gateway": {
    "controlUi": {
      "dangerouslyAllowHostHeaderOriginFallback": true
    }
  }
}
EOF

exec openclaw gateway --port 18789 --bind lan
