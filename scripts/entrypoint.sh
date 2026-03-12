#!/bin/bash
set -e

cp -a /opt/preinstall/. /home/ 2>/dev/null || true

mkdir -p /home/go ~/.openclaw

if [ -z "$OPENCLAW_GATEWAY_TOKEN" ]; then
    echo "Error: OPENCLAW_GATEWAY_TOKEN environment variable is not set"
    echo ""
    echo "Please set the token before starting:"
    echo "  export OPENCLAW_GATEWAY_TOKEN=your_token_here"
    echo ""
    echo "Or run with:"
    echo "  docker run -e OPENCLAW_GATEWAY_TOKEN=your_token_here ..."
    exit 1
fi

cat > ~/.openclaw/openclaw.json << EOF
{
  "gateway": {
    "mode": "local",
    "controlUi": {
      "dangerouslyAllowHostHeaderOriginFallback": true,
      "allowInsecureAuth": true,
      "dangerouslyDisableDeviceAuth": true
    },
    "auth": {
      "mode": "token",
      "token": "$OPENCLAW_GATEWAY_TOKEN"
    }
  },
  "tools": {
    "profile": "full"
  }
}
EOF

exec openclaw gateway --port 18789 --bind lan
