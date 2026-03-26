#!/usr/bin/env bash
# Stop Project N.O.M.A.D (macOS M-Series)
set -euo pipefail

NOMAD_DIR="${NOMAD_DIR:-$HOME/project-nomad}"
CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

cd "$NOMAD_DIR"

echo -e "${CYAN}==> Stopping Project N.O.M.A.D...${NC}"

# Stop Docker containers
if docker info &>/dev/null 2>&1; then
  docker compose --env-file .env down
  echo -e "${GREEN}✓ Docker containers stopped.${NC}"
else
  echo -e "${YELLOW}Docker is not running — containers already stopped.${NC}"
fi

# Optionally stop native Ollama
read -r -p "Stop native Ollama service too? [y/N] " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
  pkill -x ollama 2>/dev/null && echo -e "${GREEN}✓ Ollama stopped.${NC}" || echo "Ollama was not running."
fi

echo ""
echo "Project N.O.M.A.D has been stopped."
echo "To start it again: ./scripts/start.sh"
