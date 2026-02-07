#!/usr/bin/env bash
set -euo pipefail

# HUMMBL Secrets Rotation Script
# Atomic rotation with rollback capability
# Base120: IN2 (premortem) - designed for failure recovery
# Base120: SY18 (telemetry) - comprehensive audit trail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
readonly LOG_DIR="${REPO_ROOT}/_state/audit/secrets"
readonly TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
readonly ROTATION_ID="rot-$(date +%s)-$$"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly NC='\033[0m' # No Color

# Supported secret stores
readonly STORE_KEYCHAIN="keychain"
readonly STORE_1PASSWORD="1password"
readonly STORE_ENV_FILE="env_file"

# Exit codes
readonly EXIT_SUCCESS=0
readonly EXIT_INVALID_ARGS=1
readonly EXIT_SECRET_NOT_FOUND=2
readonly EXIT_ROTATION_FAILED=3
readonly EXIT_VERIFICATION_FAILED=4
readonly EXIT_ROLLBACK_FAILED=5

# Ensure log directory exists
mkdir -p "$LOG_DIR"

#######################################
# Print usage information
#######################################
usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS] <secret-name>

Rotate a secret with atomic operations and rollback capability.

OPTIONS:
  -s, --store <store>     Secret store: keychain, 1password, env_file (default: keychain)
  -t, --tier <tier>       Priority tier: 1-4 (1=critical, 4=low priority)
  -f, --force             Skip confirmation prompt
  -n, --dry-run           Show what would be done without making changes
  -v, --verify-only       Only verify the secret exists, don't rotate
  --rollback <id>         Rollback to previous value using rotation ID
  -h, --help              Show this help message

EXAMPLES:
  $(basename "$0") OPENAI_API_KEY                    # Rotate using keychain
  $(basename "$0") -s 1password STRIPE_SECRET_KEY    # Rotate using 1Password
  $(basename "$0") --rollback rot-1234567890-12345   # Rollback a rotation
  $(basename "$0") -n DATABASE_PASSWORD              # Dry run

TIER PRIORITY:
  Tier 1: Payment, auth tokens - rotate within 1 hour
  Tier 2: Database, API keys - rotate within 4 hours
  Tier 3: Third-party integrations - rotate within 24 hours
  Tier 4: Internal services - rotate within 72 hours

AUDIT TRAIL:
  All rotations are logged to: $LOG_DIR/

EOF
  exit "${1:-0}"
}

#######################################
# Log audit event
# Arguments:
#   $1 - Event type (rotate_start, rotate_success, rotate_failed, rollback)
#   $2 - Secret name
#   $3 - Additional data (JSON)
#######################################
emit_audit_event() {
  local event_type="$1"
  local secret_name="$2"
  local additional_data="${3:-{}}"

  local audit_file="${LOG_DIR}/rotation-${ROTATION_ID}.jsonl"

  # Never log the actual secret value
  # Base120: IN10 (adversarial) - assume logs could be exposed
  cat >> "$audit_file" <<EOF
{"event":"secret.${event_type}","rotation_id":"${ROTATION_ID}","secret_name":"${secret_name}","timestamp":"${TIMESTAMP}","store":"${STORE}","tier":"${TIER}","data":${additional_data}}
EOF

  # Also emit to stderr for immediate visibility
  echo -e "${YELLOW}[AUDIT]${NC} secret.${event_type}: ${secret_name}" >&2
}

#######################################
# Get secret from keychain
# Arguments:
#   $1 - Secret name
# Returns:
#   Secret value on stdout, empty if not found
#######################################
get_keychain_secret() {
  local name="$1"
  security find-generic-password -a "$USER" -s "$name" -w 2>/dev/null || true
}

#######################################
# Set secret in keychain
# Arguments:
#   $1 - Secret name
#   $2 - Secret value
#######################################
set_keychain_secret() {
  local name="$1"
  local value="$2"

  # Delete existing if present (keychain requires this for update)
  security delete-generic-password -a "$USER" -s "$name" 2>/dev/null || true

  # Add new secret
  security add-generic-password -a "$USER" -s "$name" -w "$value"
}

#######################################
# Get secret from 1Password
# Arguments:
#   $1 - Secret name
# Returns:
#   Secret value on stdout, empty if not found
#######################################
get_1password_secret() {
  local name="$1"

  if ! command -v op &>/dev/null; then
    echo -e "${RED}ERROR:${NC} 1Password CLI (op) not installed" >&2
    return 1
  fi

  op item get "$name" --fields password 2>/dev/null || true
}

#######################################
# Set secret in 1Password
# Arguments:
#   $1 - Secret name
#   $2 - Secret value
#######################################
set_1password_secret() {
  local name="$1"
  local value="$2"

  if ! command -v op &>/dev/null; then
    echo -e "${RED}ERROR:${NC} 1Password CLI (op) not installed" >&2
    return 1
  fi

  # Edit existing or create new
  if op item get "$name" &>/dev/null; then
    op item edit "$name" "password=$value"
  else
    op item create --category=password --title="$name" "password=$value"
  fi
}

#######################################
# Get secret from env file
# Arguments:
#   $1 - Secret name
# Returns:
#   Secret value on stdout, empty if not found
#######################################
get_env_file_secret() {
  local name="$1"
  local env_file="${ENV_FILE:-$HOME/.env.local}"

  if [[ -f "$env_file" ]]; then
    grep "^${name}=" "$env_file" 2>/dev/null | cut -d= -f2- | tr -d '"' || true
  fi
}

#######################################
# Set secret in env file
# Arguments:
#   $1 - Secret name
#   $2 - Secret value
#######################################
set_env_file_secret() {
  local name="$1"
  local value="$2"
  local env_file="${ENV_FILE:-$HOME/.env.local}"

  # Create backup
  if [[ -f "$env_file" ]]; then
    cp "$env_file" "${env_file}.bak.${ROTATION_ID}"
  fi

  # Remove existing and append new
  if [[ -f "$env_file" ]]; then
    grep -v "^${name}=" "$env_file" > "${env_file}.tmp" || true
    mv "${env_file}.tmp" "$env_file"
  fi

  echo "${name}=\"${value}\"" >> "$env_file"
  chmod 600 "$env_file"
}

#######################################
# Get secret using configured store
# Arguments:
#   $1 - Secret name
#######################################
get_secret() {
  local name="$1"
  case "$STORE" in
    "$STORE_KEYCHAIN")
      get_keychain_secret "$name"
      ;;
    "$STORE_1PASSWORD")
      get_1password_secret "$name"
      ;;
    "$STORE_ENV_FILE")
      get_env_file_secret "$name"
      ;;
    *)
      echo -e "${RED}ERROR:${NC} Unknown store: $STORE" >&2
      return 1
      ;;
  esac
}

#######################################
# Set secret using configured store
# Arguments:
#   $1 - Secret name
#   $2 - Secret value
#######################################
set_secret() {
  local name="$1"
  local value="$2"
  case "$STORE" in
    "$STORE_KEYCHAIN")
      set_keychain_secret "$name" "$value"
      ;;
    "$STORE_1PASSWORD")
      set_1password_secret "$name" "$value"
      ;;
    "$STORE_ENV_FILE")
      set_env_file_secret "$name" "$value"
      ;;
    *)
      echo -e "${RED}ERROR:${NC} Unknown store: $STORE" >&2
      return 1
      ;;
  esac
}

#######################################
# Generate new secret value
# Arguments:
#   $1 - Secret name (used to determine format)
# Returns:
#   New secret value on stdout
#######################################
generate_new_secret() {
  local name="$1"

  # Different formats for different secret types
  # Base120: P2 (stakeholder perspective) - match expected formats
  case "$name" in
    *API_KEY* | *SECRET_KEY*)
      # 40-character alphanumeric
      openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c 40
      ;;
    *PASSWORD*)
      # 32-character with special chars
      openssl rand -base64 32 | head -c 32
      ;;
    *TOKEN*)
      # 64-character hex
      openssl rand -hex 32
      ;;
    *)
      # Default: 32-character alphanumeric
      openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c 32
      ;;
  esac
}

#######################################
# Save rollback information
# Arguments:
#   $1 - Secret name
#   $2 - Old value (will be stored securely)
#######################################
save_rollback_info() {
  local name="$1"
  local old_value="$2"

  local rollback_file="${LOG_DIR}/.rollback-${ROTATION_ID}"

  # Store old value in keychain for rollback (never in plaintext file)
  # This is a backup mechanism only
  set_keychain_secret "rollback-${ROTATION_ID}-${name}" "$old_value"

  # Store metadata (not the value)
  cat > "$rollback_file" <<EOF
{
  "rotation_id": "${ROTATION_ID}",
  "secret_name": "${name}",
  "store": "${STORE}",
  "timestamp": "${TIMESTAMP}",
  "rollback_key": "rollback-${ROTATION_ID}-${name}"
}
EOF
  chmod 600 "$rollback_file"

  echo -e "${GREEN}Rollback saved:${NC} $ROTATION_ID"
}

#######################################
# Perform rollback
# Arguments:
#   $1 - Rotation ID to rollback
#######################################
perform_rollback() {
  local rollback_id="$1"
  local rollback_file="${LOG_DIR}/.rollback-${rollback_id}"

  if [[ ! -f "$rollback_file" ]]; then
    echo -e "${RED}ERROR:${NC} Rollback information not found for: $rollback_id" >&2
    exit $EXIT_ROLLBACK_FAILED
  fi

  local secret_name
  local rollback_key
  local orig_store

  secret_name=$(jq -r '.secret_name' "$rollback_file")
  rollback_key=$(jq -r '.rollback_key' "$rollback_file")
  orig_store=$(jq -r '.store' "$rollback_file")

  # Get old value from keychain rollback storage
  local old_value
  old_value=$(get_keychain_secret "$rollback_key")

  if [[ -z "$old_value" ]]; then
    echo -e "${RED}ERROR:${NC} Could not retrieve rollback value" >&2
    exit $EXIT_ROLLBACK_FAILED
  fi

  emit_audit_event "rollback_start" "$secret_name" "{\"rollback_from\":\"${rollback_id}\"}"

  # Restore to original store
  STORE="$orig_store"
  if set_secret "$secret_name" "$old_value"; then
    emit_audit_event "rollback_success" "$secret_name" "{\"rollback_from\":\"${rollback_id}\"}"
    echo -e "${GREEN}SUCCESS:${NC} Rolled back $secret_name to pre-rotation value"

    # Clean up rollback data
    security delete-generic-password -a "$USER" -s "$rollback_key" 2>/dev/null || true
    rm -f "$rollback_file"
  else
    emit_audit_event "rollback_failed" "$secret_name" "{\"rollback_from\":\"${rollback_id}\"}"
    echo -e "${RED}FAILED:${NC} Could not rollback $secret_name" >&2
    exit $EXIT_ROLLBACK_FAILED
  fi
}

#######################################
# Verify secret is accessible
# Arguments:
#   $1 - Secret name
#######################################
verify_secret() {
  local name="$1"
  local value
  value=$(get_secret "$name")

  if [[ -n "$value" ]]; then
    echo -e "${GREEN}VERIFIED:${NC} $name exists in $STORE"
    return 0
  else
    echo -e "${RED}NOT FOUND:${NC} $name not found in $STORE" >&2
    return 1
  fi
}

#######################################
# Main rotation logic
# Arguments:
#   $1 - Secret name
#######################################
rotate_secret() {
  local name="$1"

  echo "Rotating secret: $name"
  echo "Store: $STORE"
  echo "Tier: $TIER"
  echo "Rotation ID: $ROTATION_ID"
  echo ""

  # Step 1: Get current value
  local old_value
  old_value=$(get_secret "$name")

  if [[ -z "$old_value" ]]; then
    echo -e "${YELLOW}WARNING:${NC} Secret not found, creating new" >&2
  fi

  # Step 2: Generate new value
  local new_value
  new_value=$(generate_new_secret "$name")

  if [[ -z "$new_value" ]]; then
    echo -e "${RED}ERROR:${NC} Failed to generate new secret" >&2
    exit $EXIT_ROTATION_FAILED
  fi

  # Dry run - show what would happen
  if [[ "$DRY_RUN" == "true" ]]; then
    echo -e "${YELLOW}DRY RUN:${NC} Would rotate $name"
    echo "  Old value length: ${#old_value}"
    echo "  New value length: ${#new_value}"
    echo "  Store: $STORE"
    exit $EXIT_SUCCESS
  fi

  # Confirmation
  if [[ "$FORCE" != "true" ]]; then
    echo -e "${YELLOW}WARNING:${NC} This will rotate $name"
    echo "Ensure all services using this secret can be updated."
    read -p "Continue? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo "Aborted."
      exit 0
    fi
  fi

  emit_audit_event "rotate_start" "$name" "{\"tier\":$TIER}"

  # Step 3: Save rollback info (only if we have an old value)
  if [[ -n "$old_value" ]]; then
    save_rollback_info "$name" "$old_value"
  fi

  # Step 4: Set new value
  # Base120: IN2 (premortem) - atomic with error handling
  if set_secret "$name" "$new_value"; then
    # Step 5: Verify new value is set
    local verify_value
    verify_value=$(get_secret "$name")

    if [[ "$verify_value" == "$new_value" ]]; then
      emit_audit_event "rotate_success" "$name" "{\"tier\":$TIER}"

      echo ""
      echo -e "${GREEN}SUCCESS:${NC} Secret rotated"
      echo "  Secret: $name"
      echo "  Store: $STORE"
      echo "  Rotation ID: $ROTATION_ID"
      echo ""
      echo "NEXT STEPS:"
      echo "  1. Update all services using this secret"
      echo "  2. Verify services are functioning"
      echo "  3. If issues occur, rollback with:"
      echo "     $(basename "$0") --rollback $ROTATION_ID"
      echo ""

      # Show masked new value for copy/paste
      local masked="${new_value:0:4}...${new_value: -4}"
      echo "New value (masked): $masked"

    else
      emit_audit_event "rotate_failed" "$name" "{\"reason\":\"verification_failed\"}"
      echo -e "${RED}ERROR:${NC} Verification failed - value mismatch" >&2

      # Attempt automatic rollback
      if [[ -n "$old_value" ]]; then
        echo "Attempting automatic rollback..."
        perform_rollback "$ROTATION_ID"
      fi

      exit $EXIT_VERIFICATION_FAILED
    fi
  else
    emit_audit_event "rotate_failed" "$name" "{\"reason\":\"set_failed\"}"
    echo -e "${RED}ERROR:${NC} Failed to set new secret" >&2
    exit $EXIT_ROTATION_FAILED
  fi
}

#######################################
# Parse arguments and run
#######################################
main() {
  # Default values
  STORE="$STORE_KEYCHAIN"
  TIER=2
  FORCE="false"
  DRY_RUN="false"
  VERIFY_ONLY="false"
  ROLLBACK_ID=""
  SECRET_NAME=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -s|--store)
        STORE="$2"
        shift 2
        ;;
      -t|--tier)
        TIER="$2"
        shift 2
        ;;
      -f|--force)
        FORCE="true"
        shift
        ;;
      -n|--dry-run)
        DRY_RUN="true"
        shift
        ;;
      -v|--verify-only)
        VERIFY_ONLY="true"
        shift
        ;;
      --rollback)
        ROLLBACK_ID="$2"
        shift 2
        ;;
      -h|--help)
        usage 0
        ;;
      -*)
        echo -e "${RED}ERROR:${NC} Unknown option: $1" >&2
        usage $EXIT_INVALID_ARGS
        ;;
      *)
        SECRET_NAME="$1"
        shift
        ;;
    esac
  done

  # Validate tier
  if ! [[ "$TIER" =~ ^[1-4]$ ]]; then
    echo -e "${RED}ERROR:${NC} Tier must be 1-4" >&2
    exit $EXIT_INVALID_ARGS
  fi

  # Handle rollback
  if [[ -n "$ROLLBACK_ID" ]]; then
    perform_rollback "$ROLLBACK_ID"
    exit $EXIT_SUCCESS
  fi

  # Require secret name for other operations
  if [[ -z "$SECRET_NAME" ]]; then
    echo -e "${RED}ERROR:${NC} Secret name required" >&2
    usage $EXIT_INVALID_ARGS
  fi

  # Verify only
  if [[ "$VERIFY_ONLY" == "true" ]]; then
    if verify_secret "$SECRET_NAME"; then
      exit $EXIT_SUCCESS
    else
      exit $EXIT_SECRET_NOT_FOUND
    fi
  fi

  # Perform rotation
  rotate_secret "$SECRET_NAME"
}

main "$@"
