#!/usr/bin/env bash
# Pulls the latest trip_io_backend code and redeploys the Phase 2
# microservices stack (gateway + user/itinerary/recommendation services +
# RabbitMQ) via Docker Compose.
#
# This is separate from update.sh on purpose - that script still deploys
# the Phase 1 monolith via systemd, untouched. Run this once you're ready
# to test (or cut over to) Phase 2; it never touches the monolith's
# systemd service.
#
# One-time setup before the FIRST run on this VPS:
#   1. Install Docker + the Compose plugin if not already present:
#        curl -fsSL https://get.docker.com | sh
#        apt-get install -y docker-compose-plugin
#   2. Seed the three services' data files from the monolith's data.json
#      (only ever run this once - re-running it later would overwrite
#      whatever Phase 2 has accumulated since with a stale snapshot):
#        python3 scripts/migrate_data.py
#   3. Create a .env file in this directory with REAL production secrets -
#      docker compose reads it automatically. Without it, every service
#      falls back to the insecure dev-only defaults in
#      docker-compose.microservices.yml (anyone could forge a JWT with the
#      well-known dev JWT_SECRET). At minimum, set:
#        JWT_SECRET=<openssl rand -hex 32>
#        INTERNAL_SERVICE_TOKEN=<openssl rand -hex 32>
#      plus whichever of GROQ_API_KEY / GOOGLE_OAUTH_CLIENT_ID / ORS_API_KEY /
#      MATOMO_API_TOKEN you use.
#
# Run from anywhere on the VPS: ./update_microservices.sh
set -euo pipefail

REPO_DIR="/root/trip_io_backend"
COMPOSE_FILE="docker-compose.microservices.yml"
GATEWAY_URL="http://127.0.0.1:8000"

cd "$REPO_DIR"

if [ ! -f .env ]; then
  echo "==> WARNING: no .env file found in $REPO_DIR"
  echo "    The stack will start with insecure dev-only defaults for"
  echo "    JWT_SECRET and INTERNAL_SERVICE_TOKEN. See the setup notes at"
  echo "    the top of this script before deploying for real."
fi

echo "==> Pulling latest changes"
git pull

echo "==> Building and starting the microservices stack"
docker compose -f "$COMPOSE_FILE" up -d --build

echo "==> Waiting for the gateway to come up"
for i in $(seq 1 60); do
  if curl -sf "$GATEWAY_URL/health" > /dev/null; then
    echo "==> Gateway is up."
    docker compose -f "$COMPOSE_FILE" ps
    exit 0
  fi
  sleep 1
done

echo "==> Gateway did not respond after startup. Recent logs:"
docker compose -f "$COMPOSE_FILE" logs --tail=50
exit 1
