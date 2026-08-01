# ---- Build stage: compile the Flutter web app ----
FROM ghcr.io/cirruslabs/flutter:stable AS build
WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

# Baked into the compiled JS at build time — Flutter web has no way to read env vars at
# runtime, so these must be supplied as Railway build-time variables (Settings -> Variables on
# this service, matching these ARG names) rather than regular runtime variables.
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
# listen port come from Railway's dynamic $PORT instead of being hardcoded.
COPY nginx.conf.template /etc/nginx/templates/default.conf.template
EXPOSE 8080
