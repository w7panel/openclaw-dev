#!/bin/bash
set -e

cp -a /opt/preinstall/. /home/ 2>/dev/null || true

mkdir -p /home/go ~/.openclaw

if [ ! -f ~/.openclaw/openclaw.json ]; then
    cat > ~/.openclaw/openclaw.json << 'EOF'
{
  "gateway": {
    "mode": "local",
    "controlUi": {
      "dangerouslyAllowHostHeaderOriginFallback": true
    },
    "auth": {
      "mode": "token"
    }
  }
}
EOF
fi

exec openclaw gateway --port 18789 --bind lan
