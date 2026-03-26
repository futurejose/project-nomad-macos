#!/usr/bin/env bash
# Check that all dependencies for Project N.O.M.A.D are present and running
set -euo pipefail

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

PASS=0; FAIL=0

check() {
  local name="$1"; local cmd="$2"
  if eval "$cmd" &>/dev/null 2>&1; then
    echo -e "  ${GREEN}✓${NC} $name"
    PASS=$((PASS+1))
  else
    echo -e "  ${RED}✗${NC} $name"
    FAIL=$((FAIL+1))
  fi
}

echo -e "${CYAN}==> Project N.O.M.A.D — Dependency Check${NC}"
echo ""

echo "Platform:"
check "macOS detected"              "[[ $(uname -s) == Darwin ]]"
check "Apple Silicon (arm64)"       "[[ $(uname -m) == arm64 ]]"
check "Rosetta 2 available"         "arch -x86_64 /usr/bin/true"

echo ""
echo "Core dependencies:"
check "Homebrew installed"          "command -v brew"
check "Docker CLI installed"        "command -v docker"
check "Docker Desktop running"      "docker info"
check "docker compose (v2)"         "docker compose version"

echo ""
echo "Services:"
check "Ollama running (port 11434)" "curl -sf http://localhost:11434"
check "NOMAD UI running (port 8080)" "curl -sf http://localhost:8080/health"
check "Open WebUI running (port 3000)" "curl -sf http://localhost:3000"

echo ""
if [[ $FAIL -eq 0 ]]; then
  echo -e "${GREEN}All checks passed! ($PASS/$((PASS+FAIL)))${NC}"
else
  echo -e "${YELLOW}$FAIL check(s) failed. Run ./install.sh to fix.${NC}"
fi
