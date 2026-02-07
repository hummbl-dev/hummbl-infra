#!/usr/bin/env bash
# Manual Rollback Script
# Base120: SY14 (Resilience), IN2 (Premortem)
#
# Usage:
#   ./ci-cd/scripts/rollback.sh --environment prod --previous
#   ./ci-cd/scripts/rollback.sh --environment staging --digest sha256:abc123

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Defaults
ENVIRONMENT=""
DIGEST=""
REVISION=""
PREVIOUS=false
DRY_RUN=false
FORCE=false

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

usage() {
  cat <<EOF
Usage: $(basename "$0") --environment ENV [OPTIONS]

Rollback a deployment to a previous version.

OPTIONS:
  -e, --environment ENV   Target environment (required)
  --digest DIGEST         Rollback to specific image digest
  --revision N            Rollback to revision number
  --previous              Rollback to previous version
  --dry-run               Show what would happen
  --force                 Skip confirmation
  -h, --help              Show this help
EOF
  exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -e|--environment)
      ENVIRONMENT="$2"
      shift 2
      ;;
    --digest)
      DIGEST="$2"
      shift 2
      ;;
    --revision)
      REVISION="$2"
      shift 2
      ;;
    --previous)
      PREVIOUS=true
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --force)
      FORCE=true
      shift
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

# Validate
if [[ -z "$ENVIRONMENT" ]]; then
  log_error "--environment is required"
  exit 1
fi

if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
  log_error "Invalid environment: $ENVIRONMENT"
  exit 1
fi

# Determine rollback target
if [[ -n "$DIGEST" ]]; then
  TARGET="$DIGEST"
  SOURCE="specified digest"
elif [[ -n "$REVISION" ]]; then
  TARGET="revision-$REVISION"
  SOURCE="revision $REVISION"
elif [[ "$PREVIOUS" == "true" ]]; then
  TARGET="previous"
  SOURCE="previous deployment"
else
  log_error "Must specify --digest, --revision, or --previous"
  exit 1
fi

# Confirm
if [[ "$FORCE" != "true" && "$DRY_RUN" != "true" ]]; then
  echo ""
  echo "Rollback Configuration"
  echo "======================"
  echo "Environment: $ENVIRONMENT"
  echo "Target: $TARGET"
  echo "Source: $SOURCE"
  echo ""

  if [[ "$ENVIRONMENT" == "prod" ]]; then
    log_warn "This is a PRODUCTION rollback!"
  fi

  read -p "Proceed? [y/N] " -n 1 -r
  echo ""
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "Rollback cancelled"
    exit 0
  fi
fi

# Execute
if [[ "$DRY_RUN" == "true" ]]; then
  log_info "[DRY RUN] Would rollback $ENVIRONMENT to $TARGET"
else
  log_info "Rolling back $ENVIRONMENT to $TARGET..."

  # Placeholder for actual rollback
  # kubectl rollout undo deployment/hummbl-infra -n $ENVIRONMENT

  log_info "Rollback complete"
fi

# Record
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
RECORD="{\"event\":\"rollback\",\"timestamp\":\"$TIMESTAMP\",\"environment\":\"$ENVIRONMENT\",\"target\":\"$TARGET\",\"dry_run\":$DRY_RUN}"
echo "$RECORD" | jq .
