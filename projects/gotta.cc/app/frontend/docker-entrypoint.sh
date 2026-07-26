#!/bin/sh
# Generate runtime config from environment variables.
# Loaded by the browser via <script src="/__env.js"> before the app hydrates.
# Helm values → K8s env vars → this script → window.__ENV

cat > /app/public/__env.js <<EOF
window.__ENV = {
  GA_MEASUREMENT_ID: "${GA_MEASUREMENT_ID:-}",
  POSTHOG_KEY: "${POSTHOG_KEY:-}",
  POSTHOG_HOST: "${POSTHOG_HOST:-}",
  API_URL: "${API_URL:-}",
  OTEL_COLLECTOR_URL: "${OTEL_COLLECTOR_URL:-}",
  ADSENSE_CLIENT: "${ADSENSE_CLIENT:-}"
};
EOF

# ads.txt must name the publisher that actually serves the ads, so derive it
# from the same env var rather than shipping a stale checked-in ID. The
# ca-pub-XXXX client ID maps to the pub-XXXX seller ID. Without ADSENSE_CLIENT
# the placeholder from public/ads.txt is left in place.
if [ -n "${ADSENSE_CLIENT:-}" ]; then
  ADS_TXT_PUB=$(printf '%s' "$ADSENSE_CLIENT" | sed 's/^ca-//')
  cat > /app/public/ads.txt <<EOF
# Generated at container start from ADSENSE_CLIENT.
google.com, ${ADS_TXT_PUB}, DIRECT, f08c47fec0942fa0
EOF
fi

exec node server.js
