# ---- Build stage: compile the Flutter web app ----
FROM ghcr.io/cirruslabs/flutter:stable AS build
WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

# Optional build-time fallback only — not required. Real config is injected at container
# *startup* instead (see docker-entrypoint-custom.sh + lib/core/config/runtime_config_web.dart),
# because Docker hosts don't reliably pass dashboard Environment Variables through as build
# args (confirmed on Render: these ARGs came through empty even with the variables set).
ARG API_BASE_URL
ARG SUPABASE_URL
ARG SUPABASE_ANON_KEY

RUN flutter build web --release \
    --dart-define=API_BASE_URL=${API_BASE_URL} \
    --dart-define=SUPABASE_URL=${SUPABASE_URL} \
    --dart-define=SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}

# ---- Serve stage: nginx serving the compiled static site ----
FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html

# Fully self-contained startup script — generates env-config.js from this container's real
# runtime environment variables, generates the nginx config with the actual $PORT, then starts
# nginx. Bypasses nginx's own /docker-entrypoint.d/ convention entirely (that wasn't reliably
# triggering on Render), so this doesn't depend on host-specific entrypoint behaviour.
COPY docker-entrypoint-custom.sh /docker-entrypoint-custom.sh
RUN chmod +x /docker-entrypoint-custom.sh

EXPOSE 8080
ENTRYPOINT ["/docker-entrypoint-custom.sh"]
