#!/usr/bin/env bash
# Update Project N.O.M.A.D to the latest version (macOS M-Series)
set -euo pipefail

NOMAD_DIR="${NOMAD_DIR:-$HOME/project-nomad}"
CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

cd "$NOMAD_DIR"

echo -e "${CYAN}==> Updating Project N.O.M.A.D...${NC}"

# Pull latest images
echo "Pulling latest Docker images..."
docker pull --platform linux/amd64 ghcr.io/crosstalk-solutions/project-nomad:latest
docker compose --env-file .env pull

# Restart with new images
echo "Restarting containers with updated images..."
docker compose --env-file .env up -d --force-recreate

# Clean up old images
echo "Removing unused Docker images..."
docker image prune -f

# Update Ollama
if command -v brew &>/dev/null; then
  echo "Updating Ollama..."
  brew upgrade --cask ollama 2>/dev/null || echo "Ollama is already up to date."
fi

echo ""
echo -e "${GREEN~✓ Update complete!${NC}"
echo ""
docker compose ps
