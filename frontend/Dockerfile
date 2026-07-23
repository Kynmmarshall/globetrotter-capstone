# trip_io frontend - builds the Flutter web app and serves it as static
# files via Nginx. Windows/Android builds aren't containerizable (Docker
# runs Linux processes, not desktop GUI apps or mobile installers), so this
# image covers the web target only.

# ---- Build stage ----
FROM ghcr.io/cirruslabs/flutter:stable AS build
WORKDIR /app

# This must be a URL the end user's BROWSER can reach - not a Docker-internal
# service name - since it gets compiled into the client-side JS bundle.
# Override at build time, e.g.:
#   docker build --build-arg API_BASE_URL=https://trip-io.duckdns.org .
ARG API_BASE_URL=http://localhost:8000

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .
RUN flutter build web --release --dart-define=API_BASE_URL=${API_BASE_URL}

# ---- Serve stage ----
FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
