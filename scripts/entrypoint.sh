#!/bin/bash
set -e

cp -a /opt/preinstall/. /home/ 2>/dev/null || true

mkdir -p /home/go ~/.openclaw

openclaw config set gateway.controlUi.dangerouslyAllowHostHeaderOriginFallback true --allow-unconfigured 2>/dev/null || true

exec openclaw gateway --port 18789 --bind lan --allow-unconfigured
