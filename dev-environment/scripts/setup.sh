#!/usr/bin/env bash
# HUMMBL Development Environment Setup
# Base120: DE3 (Decomposition) - Modular, idempotent setup
#
# Usage:
#   ./dev-environment/scripts/setup.sh           # Run all steps
#   ./dev-environment/scripts/setup.sh --step 3  # Run specific step
#   ./dev-environment/scripts/setup.sh --from 4  # Start from step 4

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Steps
STEPS=(
  "01-system-check.sh"
  "02-install-deps.sh"
  "03-configure-shell.sh"
  "04-setup-docker.sh"
  "05-setup-git.sh"
  "06-setup-secrets.sh"
  "07-verify-install.sh"
)

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

HUMMBL Development Environment Setup

OPTIONS:
  --step N      Run only step N (1-7)
  --from N      Start from step N
  --list        List all steps
  -h, --help    Show this help

STEPS:
  1. System check (macOS, Xcode, Homebrew)
  2. Install dependencies (fnm, Node, pnpm, gitleaks)
  3. Configure shell (modules, PATH)
  4. Setup Docker (Colima or Docker Desktop)
  5. Setup git (hooks, gitleaks)
  6. Setup secrets (vault structure)
  7. Verify installation
EOF
  exit 0
}

list_steps() {
  echo "Setup Steps:"
  for i in "${!STEPS[@]}"; do
    echo "  $((i+1)). ${STEPS[$i]}"
  done
  exit 0
}

run_step() {
  local step="$1"
  local script="$SCRIPT_DIR/$step"

  if [[ ! -f "$script" ]]; then
    log_warn "Script not found: $script (skipping)"
    return 0
  fi

  if [[ ! -x "$script" ]]; then
    chmod +x "$script"
  fi

  echo ""
  echo "========================================"
  echo "  Running: $step"
  echo "========================================"
  echo ""

  if "$script"; then
    log_success "Completed: $step"
  else
    log_error "Failed: $step"
    return 1
  fi
}

# Parse arguments
ONLY_STEP=""
FROM_STEP=1

while [[ $# -gt 0 ]]; do
  case $1 in
    --step)
      ONLY_STEP="$2"
      shift 2
      ;;
    --from)
      FROM_STEP="$2"
      shift 2
      ;;
    --list)
      list_steps
      ;;
    -h|--help)
      usage
      ;;
    *)
      log_error "Unknown option: $1"
      usage
      ;;
  esac
done

# Main
echo ""
echo "========================================"
echo "  HUMMBL Development Environment Setup"
echo "========================================"
echo ""

if [[ -n "$ONLY_STEP" ]]; then
  if [[ "$ONLY_STEP" -lt 1 || "$ONLY_STEP" -gt ${#STEPS[@]} ]]; then
    log_error "Invalid step: $ONLY_STEP (valid: 1-${#STEPS[@]})"
    exit 1
  fi
  run_step "${STEPS[$((ONLY_STEP-1))]}"
else
  for i in "${!STEPS[@]}"; do
    step_num=$((i+1))
    if [[ $step_num -ge $FROM_STEP ]]; then
      run_step "${STEPS[$i]}" || exit 1
    fi
  done
fi

echo ""
echo "========================================"
echo "  Setup Complete!"
echo "========================================"
echo ""
echo "Next steps:"
echo "  1. Reload shell: source ~/.zshrc"
echo "  2. Start services: cd dev-environment/docker && docker compose up -d"
echo "  3. Run doctor: ./scripts/doctor.sh"
echo ""
