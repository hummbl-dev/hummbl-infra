#!/usr/bin/env bash
set -euo pipefail

# HUMMBL Infrastructure Doctor
# Health check for development environment

ERRORS=0
WARNINGS=0

echo "HUMMBL Infrastructure Doctor"
echo "============================="
echo ""

# Check 1: Node version
check_node() {
  echo "Checking Node.js..."
  if command -v node &>/dev/null; then
    local version
    version=$(node --version | sed 's/v//' | cut -d. -f1)
    if [[ "$version" -ge 22 ]]; then
      echo "  ✓ Node v$(node --version | sed 's/v//') (required: 22+)"
    else
      echo "  ✗ Node $(node --version) too old (required: 22+)"
      ((ERRORS++))
    fi
  else
    echo "  ✗ Node not found"
    ((ERRORS++))
  fi
}

# Check 2: pnpm
check_pnpm() {
  echo "Checking pnpm..."
  if command -v pnpm &>/dev/null; then
    echo "  ✓ pnpm $(pnpm --version)"
  else
    echo "  ✗ pnpm not found (install: npm i -g pnpm)"
    ((ERRORS++))
  fi
}

# Check 3: Docker
check_docker() {
  echo "Checking Docker..."
  if command -v docker &>/dev/null; then
    if docker info &>/dev/null; then
      echo "  ✓ Docker running"
    else
      echo "  ⚠ Docker installed but not running"
      ((WARNINGS++))
    fi
  else
    echo "  ⚠ Docker not found"
    ((WARNINGS++))
  fi
}

# Check 4: gitleaks
check_gitleaks() {
  echo "Checking gitleaks..."
  if command -v gitleaks &>/dev/null; then
    echo "  ✓ gitleaks $(gitleaks version 2>/dev/null || echo 'installed')"
  else
    echo "  ⚠ gitleaks not found (install: brew install gitleaks)"
    ((WARNINGS++))
  fi
}

# Check 5: 1Password CLI
check_1password() {
  echo "Checking 1Password CLI..."
  if command -v op &>/dev/null; then
    if op whoami &>/dev/null 2>&1; then
      echo "  ✓ 1Password CLI (signed in)"
    else
      echo "  ⚠ 1Password CLI installed but not signed in"
      ((WARNINGS++))
    fi
  else
    echo "  - 1Password CLI not found (optional)"
  fi
}

# Check 6: Secrets exposure
check_secrets() {
  echo "Checking for exposed secrets..."
  local exposed=0

  if [[ -f "$HOME/.env.local" ]]; then
    if grep -q "sk-" "$HOME/.env.local" 2>/dev/null; then
      echo "  ⚠ Potential API keys in ~/.env.local"
      ((exposed++))
    fi
  fi

  if [[ -f "$HOME/.secrets" ]]; then
    local perms
    perms=$(stat -f "%OLp" "$HOME/.secrets" 2>/dev/null || stat -c "%a" "$HOME/.secrets" 2>/dev/null || echo "unknown")
    if [[ "$perms" != "600" ]]; then
      echo "  ⚠ ~/.secrets has permissions $perms (should be 600)"
      ((exposed++))
    fi
  fi

  if [[ $exposed -eq 0 ]]; then
    echo "  ✓ No obvious secrets exposure"
  else
    ((WARNINGS += exposed))
  fi
}

# Check 7: Git hooks
check_hooks() {
  echo "Checking git hooks..."
  local hooks_dir
  hooks_dir="$(git rev-parse --git-dir 2>/dev/null)/hooks"

  if [[ -x "$hooks_dir/pre-commit" ]]; then
    echo "  ✓ pre-commit hook installed"
  else
    echo "  ⚠ pre-commit hook not installed"
    ((WARNINGS++))
  fi
}

# Run all checks
check_node
check_pnpm
check_docker
check_gitleaks
check_1password
check_secrets
check_hooks

# Summary
echo ""
echo "============================="
if [[ $ERRORS -gt 0 ]]; then
  echo "❌ $ERRORS error(s), $WARNINGS warning(s)"
  echo "Run ./scripts/setup.sh to fix issues"
  exit 1
elif [[ $WARNINGS -gt 0 ]]; then
  echo "⚠️  $WARNINGS warning(s) (non-blocking)"
  echo "Environment usable but consider fixing warnings"
  exit 0
else
  echo "✅ All checks passed!"
  exit 0
fi
