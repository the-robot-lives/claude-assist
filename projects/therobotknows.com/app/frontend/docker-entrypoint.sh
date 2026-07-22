#!/bin/sh
# Optional runtime config for browser (mirrors start-app pattern).
mkdir -p /app/public 2>/dev/null || true
cat > /app/public/__env.js <<EOF
window.__ENV = {
  API_URL: "${API_URL:-${NEXT_PUBLIC_API_URL:-}}",
  APP_URL: "${APP_URL:-}",
  API_MODE: "${NEXT_PUBLIC_API_MODE:-live}"
};
EOF

exec node server.js
