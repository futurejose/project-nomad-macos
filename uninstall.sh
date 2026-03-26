#!/usr/bin/env bash
# Uninstall Project N.O.M.A.D (macOS M-Series)
# WARNING: This will stop all containers and optionally delete all data.
set -euo pipefail

NOMAD_DIR="${NOMAD_DIR:-$HOME/project-nomad}"
RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'; NC='\033[0m'

echo -e "${YELLOW}==> Project N.O.M.A.D Uninstaller${NC}"
echo ""
echo -e "${RED}WARNING: This will stop all NOMAD containers.${NC}"
echo ""
read -r -p "Continue with uninstall? [y/N] " answer
[[ "$answer" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }

cd "$NOMAD_DIR" 2>/dev/null || true

# Stop and remove containers + networks
if docker info &>/dev/null 2>&1 && [[ -f "$NOMAD_DIR/docker-compose.yml" ]]; then
  echo "Stopping and removing containers..."
  docker compose down --remove-orphans 2>/dev/null || true
fi

# Remove LaunchAgent if installed
if [[ -f "$HOME/Library/LaunchAgents/com.projectnomad.plist" ]]; then
  launchctl unload "$HOME/Library/LaunchAgents/com.projectnomad.plist" 2>/dev/null || true
  rm "$HOME/Library/LaunchAgents/com.projectnomad.plist"
  echo "LaunchAgent removed."
fi

# Optionally delete data
echo ""
echo -e "${RED}Do you want to delete ALL NOMAD data? (ZIM files, AI data, settings)${NC}"
echo "  Data directory: $NOMAD_DIR"
read -r -p "DELETE ALL DATA? This cannot be undone. [y/N] " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
  # Also remove named Docker volumes
  docker volume rm nomad_data qdrant_data open_webui_data kolibri_data 2>/dev/null || true
  rm -rf "$NOMAD_DIR"
  echo -e "${GREEN}All NOMAD data deleted.${NC}"
else
  echo "Data preserved at $NOMAD_DIR"
fi

echo ""
echo -e "${GREEN}Project N.O.M.A.D has been uninstalled.${NC}"
echo "Ollama was NOT removed. To uninstall it: brew uninstall --cask ollama"
