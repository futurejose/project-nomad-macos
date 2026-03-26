#!/usr/bin/env bash
# Start Project N.O.M.A.D (macOS M-Series)
set -euo pipefail

NOMAD_DIR="${NOMAD_DIR:-$HOME/project-nomad}"
CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

cd "$NOMAD_DIR"

echo -e "${CYAN}==> Starting Project N.O.M.A.D...${NC}"

# 1. Check Docker Desktop is running
if ! docker info &>/dev/null 2>&1; then
  echo -e "${YELLOW}Docker Desktop is not running. Opening it...${NC}"
  open -a Docker
  echo "Waiting for Docker to start..."
  for i in $(seq 1 18); do
    sleep 5
    docker info &>/dev/null 2>&1 && break
    echo -n "."
  done
  echo ""
  docker info &>/dev/null 2>&1 || { echo "Docker failed to start. Please open Docker Desktop manually."; exit 1; }
fi

# 2. Start native Ollama if not running
if ! pgrep -x "ollama" &>/dev/null && ! curl -s http://localhost:11434 &>/dev/null 2>&1; then
  echo -e "${CYAN}Starting Ollama...${NC}"
  nohup ollama serve &>/dev/null &
  sleep 2
fi

# 3. Start containers
echo -e "${CYAN}Starting Docker containers...${NC}"
docker compose --env-file .env up -d

echo ""
echo -e "${GREEN}✓ Project N.O.M.A.D is running!${NC}"
echo ""
echo "  NOMAD Command Center:  http://localhost:${NOMAD_PORT:-8080}"
echo "  Open WebUI (AI Chat):  http://localhost:${OPEN_WEBUI_PORT:-3000}"
echo "  Ollama API:            http://localhost:11434"
echo ""
echo "  Run 'docker compose ps' to check container status."
