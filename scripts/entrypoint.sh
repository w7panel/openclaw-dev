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

PREINSTALL_CONFIG="/opt/preinstall/preinstall-openclaw.json"
USER_CONFIG="$HOME/.openclaw/openclaw.json"

if [ -f "$PREINSTALL_CONFIG" ]; then
    if [ -f "$USER_CONFIG" ]; then
        TMP_CONFIG=$(mktemp)
        jq -s ".[1] * .[0]" "$PREINSTALL_CONFIG" "$USER_CONFIG" > "$TMP_CONFIG"
        MERGED_CONFIG="$TMP_CONFIG"
    else
        MERGED_CONFIG="$PREINSTALL_CONFIG"
    fi

    CONFIG_CONTENT=$(cat "$MERGED_CONFIG")
    for VAR in $(compgen -e); do
        VALUE="${!VAR}"
        CONFIG_CONTENT="${CONFIG_CONTENT//__${VAR}__/$VALUE}"
    done
    echo "$CONFIG_CONTENT" > "$USER_CONFIG"

    [ -f "$TMP_CONFIG" ] && rm -f "$TMP_CONFIG"
fi

exec openclaw gateway --port 18789 --bind lan
