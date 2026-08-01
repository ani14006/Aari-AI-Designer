#!/bin/sh
# Fully self-contained container startup — does not rely on nginx's own
# /docker-entrypoint.d/ convention (which wasn't reliably triggering the runtime config
# injection in production). Generates the runtime config JS + the nginx config directly, then
# execs nginx itself.
set -e

echo "[entrypoint] Generating env-config.js (API_BASE_URL=${API_BASE_URL:-<empty>}, SUPABASE_URL=${SUPABASE_URL:-<empty>})"
cat <<EOF > /usr/share/nginx/html/env-config.js
window.API_BASE_URL = "${API_BASE_URL:-}";
window.SUPABASE_URL = "${SUPABASE_URL:-}";
window.SUPABASE_ANON_KEY = "${SUPABASE_ANON_KEY:-}";
EOF

PORT="${PORT:-8080}"
echo "[entrypoint] Generating nginx config, listening on port ${PORT}"
cat <<EOF > /etc/nginx/conf.d/default.conf
server {
    listen ${PORT};
    server_name _;
    root /usr/share/nginx/html;
    index index.html;

    location / {
        try_files \$uri \$uri/ /index.html;
    }
}
EOF

echo "[entrypoint] Starting nginx"
exec nginx -g "daemon off;"
