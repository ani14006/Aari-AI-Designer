# ---- Build stage: compile the Flutter web app ----
FROM ghcr.io/cirruslabs/flutter:stable AS build
WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

# Optional build-time fallback only — not required. Real config is injected at container
# *startup* instead (see env-config-entrypoint.sh + lib/core/config/runtime_config_web.dart),
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
# nginx's official image envsubst-templates any /etc/nginx/templates/*.template file into
# /etc/nginx/conf.d/ at container start, substituting only variables that are actually set in
# the environment (nginx directives like $uri are left untouched) — this is what lets the
# listen port come from Railway's/Render's dynamic $PORT instead of being hardcoded.
COPY nginx.conf.template /etc/nginx/templates/default.conf.template
# Runs before nginx starts (nginx:alpine's own entrypoint executes every script in
# /docker-entrypoint.d/ in alphabetical order) — overwrites the placeholder env-config.js with
# this container's real runtime environment variables.
COPY env-config-entrypoint.sh /docker-entrypoint.d/50-env-config.sh
RUN chmod +x /docker-entrypoint.d/50-env-config.sh
EXPOSE 8080
