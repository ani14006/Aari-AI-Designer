#!/bin/sh
# Runs automatically before nginx starts (nginx:alpine's docker-entrypoint.sh executes every
# script in /docker-entrypoint.d/ in alphabetical order). Overwrites the placeholder
# env-config.js with real values from this container's actual runtime environment variables —
# see frontend/lib/core/config/runtime_config_web.dart for why this replaced baking config in
# at `flutter build web` time.
set -e

cat <<EOF > /usr/share/nginx/html/env-config.js
window.API_BASE_URL = "${API_BASE_URL:-}";
window.SUPABASE_URL = "${SUPABASE_URL:-}";
window.SUPABASE_ANON_KEY = "${SUPABASE_ANON_KEY:-}";
EOF
