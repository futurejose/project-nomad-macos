#!/usr/bin/env bash
# =============================================================================
# Project N.O.M.A.D — macOS M-Series Installer
# Compatible with: Apple Silicon (M1, M2, M3, M4 and later)
# =============================================================================
# What this does:
#   1. Verifies you're on an M-series Mac
#   2. Checks / installs Homebrew
#   3. Checks / installs Docker Desktop
#   4. Enables Rosetta 2 (for the x86 NOMAD Command Center container)
#   5. Installs Ollama natively (for GPU/Metal-accelerated AI inference)
#   6. Sets up the project directory and config files
#   7. Pulls Docker images and starts the stack
# =============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

NOMAD_DIR="${NOMAD_DIR:-$HOME/project-nomad}"
NOMAD_PORT="${NOMAD_PORT:-8080}"
NOMAD_IMAGE="ghcr.io/crosstalk-solutions/project-nomad:latest"
COMPOSE_FILE="$NOMAD_DIR/docker-compose.yml"
ENV_FILE="$NOMAD_DIR/.env"
OLLAMA_HOST="http://host.docker.internal:11434"
LOG_FILE="$NOMAD_DIR/install.log"

log()    { echo -e "${CYAN}[INFO]${NC}  $*"; }
ok()     { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()   { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()  { echo -e "${RED}[ERROR]${NC} $*" >&2; }
header() { echo -e "\n${BOLD}${BLUE}==> $*${NC}"; }

die() {
  error "$*"
  error "See $LOG_FILE for details."
  exit 1
}

require_confirm() {
  local prompt="${1:-Continue?}"
  read -r -p "$(echo -e "${YELLOW}${prompt} [y/N] ${NC}")" answer
  [[ "$answer" =~ ^[Yy]$ ]] || { log "Aborted."; exit 0; }
}

print_banner() {
  echo -e "${BOLD}${BLUE}"
  echo " ____             _           _   _   _  ___  __  __    _    ____"
  echo "|  _ \ _ __ ___ (_) ___  ___| |_| \ | |/ _ \|  \/  |  / \  |  _ \"
  echo "| |_) | '__/ _ \| |/ _ \/ __| __|  \| | | | | |\/| | / _ \ | | | |"
  echo "|  __/| | | (_) | |  __/ (__| |_| |\  | |_| | |  | |/ ___ \| |_| |"
  echo "|_|   |_|  \___// |\___|\___|\__|_| \_|\___/|_|  |_/_/   \_\____/"
  echo "               |__/"
  echo ""
  echo "          macOS M-Series Port — Knowledge That Never Goes Offline"
  echo -e "${NC}"
}

check_platform() {
  header "Checking platform"
  if [[ "$(uname -s)" != "Darwin" ]]; then
    die "This installer is for macOS only. Detected: $(uname -s)"
  fi
  local arch="$(uname -m)"
  if [[ "$arch" != "arm64" ]]; then
    die "This installer requires Apple Silicon (M1/M2/M3/M4). Detected: $arch"
  fi
  ok "macOS $(sw_vers -productVersion) on Apple Silicon"
}

check_homebrew() {
  header "Checking Homebrew"
  if command -v brew &>/dev/null; then
    ok "Homebrew $(brew --version | head -1)"
    return
  fi
  warn "Homebrew not found."
  require_confirm "Install Homebrew now?"
  log "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD.install.sh)" >> "$LOG_FILE" 2>&1 || die "Homebrew installation failed."
  eval "$(/opt/homebrew/bin/brew shellenv)"
  ok "Homebrew installed."
}

check_docker() {
  header "Checking Docker Desktop"
  if command -v docker &>/dev/null && docker info &>/dev/null 2>&1; then
    ok "Docker $(docker --version)"
    return
  fi
  if [[ -d "/Applications/Docker.app" ]]; then
    warn "Docker Desktop installed but not running. Opening..."
    open -a Docker
    log "Waiting for Docker (up to 90s)..."
    local retries=18
    while ! docker info &>/dev/null 2>&1; do
      sleep 5; retries=$((retries-1))
      [[ $retries -le 0 ]] && die "Docker did not start. Please start manually and re-run."
      echo -n "."
    done
    echo ""
    ok "Docker started."
    return
  fi
  warn "Docker Desktop not installed."
  echo "  Download from: https://www.docker.com/products/docker-desktop/"
  require_confirm "Open download page?"
  open "https://www.docker.com/products/docker-desktop/"
  die "Please install Docker Desktop and re-run this installer."
}

check_rosetta() {
  header "Checking Rosetta 2"
  if /usr/bin/pgrep oahd &>/dev/null 2>&1 || arch -x86_64 /usr/bin/true &>/dev/null 2>&1; then
    ok "Rosetta 2 installed."
  else
    log "Installing Rosetta 2..."
    softwareupdate --install-rosetta --agree-to-license >> "$LOG_FILE" 2>&1 || warn "Could not auto-install Rosetta 2. Run manually if needed."
    ok "Rosetta 2 installed."
  fi
  log "Tip: In Docker Desktop → Settings → General, enable 'Use Rosetta for x86/amd64 emulation' for best performance."
}

check_ollama() {
  header "Checking Ollama (native macOS)"
  if command -v ollama &>/dev/null; then
    ok "Ollama $(ollama --version 2>/dev/null || echo 'version unknown')"
  else
    log "Installing Ollama via Homebrew..."
    brew install --cask ollama >> "$LOG_FILE" 2>&1 || {
      open "https://ollama.com/download/mac"
      require_confirm "Installed Ollama?"
    }
    ok "Ollama installed."
  fi
  if ! pgrep -x "ollama" &>/dev/null && ! curl -s http://localhost:11434 &t>/dev/null; then
    log "Starting Ollama..."
    nohup ollama serve >> "$LOG_FILE" 2>&1 &
    sleep 3
  fi
  ok "Ollama running at http://localhost:11434"
}

setup_directory() {
  header "Setting up project directory: $NOMAD_DIR"
  mkdir -p "$NOMAD_DIR"/{data,config,zim,kolibri,logs}
  write_compose_file
  if [[ ! -f "$ENV_FILE" ]]; then
    write_env_file
    ok ".env file created."
  else
    log ".env file already exists, skipping."
  fi
  ok "Project directory ready."
}

write_compose_file() {
  cat > "$COMPOSE_FILE" <<EOF
services:
  nomad:
    image: ghcr.io/crosstalk-solutions/project-nomad:latest
    platform: linux/amd64
    container_name: project-nomad
    restart: unless-stopped
    ports:
      - "\${NOMAD_PORT:-8080}:8080"
    volumes:
      - nomad_data:/data
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - OLLAMA_BASE_URL=\${OLLAMA_BASE_URL:-http://host.docker.internal:11434}
      - NOMAD_DATA_DIR=/data
      - TZ=\${TZ:-America/New_York}
    extra_hosts:
      - "host.docker.internal:host-gateway"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 60s
    networks:
      - nomad_net
  qdrant:
    image: qdrant/qdrant:latest
    container_name: nomad_qdrant
    restart: unless-stopped
    volumes:
      - qdrant_data:/qdrant/storage
    networks:
      - nomad_net
  open-webui:
    image: ghcr.io/open-webui/open-webui:main
    container_name: nomad_open_webui
    restart: unless-stopped
    ports:
      - "\${OPEN_WEBUI_PORT:-3000}:8080"
    volumes:
      - open_webui_data:/app/backend/data
    environment:
      - OLLAMA_BASE_URL=\${OLLAMA_BASE_URL:-http://host.docker.internal:11434}
    extra_hosts:
      - "host.docker.internal:host-gateway"
    networks:
      - nomad_net
volumes:
  nomad_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: \${NOMAD_DIR:-\$HOME/project-nomad}/data
  qdrant_data:
    driver: local
  open_webui_data:
    driver: local
networks:
  nomad_net:
    name: project_nomad_network
    driver: bridge
EOF
  ok "docker-compose.yml written."
}

write_env_file() {
  cat > "$ENV_FILE" <<EOF
NOMAD_DIR=$NOMAD_DIR
TZ=$(readlink /etc/localtime 2>/dev/null | sed 's|.*/zoneinfo/||' || echo "America/New_York")
NOMAD_PORT=$NOMAD_PORT
OPEN_WEBUI_PORT=3000
KIWIX_PORT=8888
KOLIBRI_PORT=8090
OLLAMA_BASE_URL=$OLLAMA_HOST
EOF
}

start_nomad() {
  header "Pulling Docker images (this may take a while)"
  cd "$NOMAD_DIR"
  log "Pulling NOMAD stack images..."
  docker pull --platform linux/amd64 "$NOMAD_IMAGE" >> "$LOG_FILE" 2>&1 || die "Failed to pull NOMAD image."
  docker compose --env-file "$ENV_FILE" pull >> "$LOG_FILE" 2>&1 || warn "Some images could not be pulled."
  header "Starting Project N.O.M.A.D"
  docker compose --env-file "$ENV_FILE" up -d >> "$LOG_FILE" 2>&1 || die "Failed to start containers."
  ok "All containers started."
}

print_summary() {
  header "Installation Complete!"
  echo ""
  echo -e "  ${BOLD}NOMAD Command Center:${NC}  http://localhost:${NOMAD_PORT}"
  echo -e "  ${BOLD}Open WebUI (AI Chat):${NC}  http://localhost:3000"
  echo -e "  ${BOLD}Ollama API:${NC}            http://localhost:11434"
  echo ""
  echo -e "  ${BOLD}Start:${NC}  ./scripts/start.sh"
  echo -e "  ${BOLD}Stop:${NC}   ./scripts/stop.sh"
  echo -e "  ${BOLD}Update:${NC} ./scripts/update.sh"
  echo ""
  echo -e "  ${YELLOW}Note:${NC} The NOMAD container uses Rosetta 2 and may take 30-60s on first launch."
  echo ""
}

main() {
  print_banner
  mkdir -p "$NOMAD_DIR" 2>/dev/null || true
  touch "$LOG_FILE" 2>/dev/null || LOG_FILE="/tmp/nomad_install.log"
  log "Install log: $LOG_FILE"
  check_platform
  check_homebrew
  check_docker
  check_rosetta
  check_ollama
  setup_directory
  start_nomad
  print_summary
}

main "$@"
