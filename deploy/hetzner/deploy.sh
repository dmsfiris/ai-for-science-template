#!/usr/bin/env bash
set -euo pipefail

# Run from repo root on the server
# Prereqs: setup-server.sh has been executed

export $(cat deploy/hetzner/.env 2>/dev/null || cat .env 2>/dev/null || echo "")

# Build images
docker compose -f docker-compose.yml -f deploy/hetzner/compose.prod.yml build

# Run stack
docker compose -f docker-compose.yml -f deploy/hetzner/compose.prod.yml up -d

echo "Deployed. Visit: https://$DOMAIN and https://api.$DOMAIN"
