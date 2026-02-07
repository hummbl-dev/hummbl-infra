# HUMMBL Infrastructure Platform

Unified infrastructure implementation for CI/CD, developer environment, monitoring, and security.

## Domains

| Domain | Directory | Purpose |
|--------|-----------|---------|
| CI/CD | `ci-cd/` | Container builds, deployments, release automation |
| Dev Environment | `dev-environment/` | Setup automation, secrets management, Docker Compose |
| Monitoring | `monitoring/` | Metrics collection, alerting, dashboards |
| Security | `security/` | RBAC, governance, compliance, incident response |

## Commands

```bash
# Setup & Validation
./scripts/doctor.sh                    # Health check
./scripts/setup.sh                     # Full setup

# Domain-specific
./ci-cd/scripts/build-container.sh     # Local container build
./dev-environment/scripts/setup.sh     # Dev environment setup
./monitoring/scripts/aggregate.sh      # Run metrics aggregation
./security/scripts/rotate-secret.sh    # Secret rotation

# Linting
./scripts/lint-all.sh                  # All lints
./scripts/lint-secrets.sh              # Secret scanning
```

## Project Structure

```
hummbl-infra/
├── ci-cd/
│   ├── configs/                 # Environment configs
│   ├── scripts/                 # Build & deploy scripts
│   ├── docs/                    # CI/CD documentation
│   └── workflows/               # GitHub Actions templates
├── dev-environment/
│   ├── configs/                 # Tool configs
│   ├── scripts/                 # Setup scripts
│   ├── docker/                  # Docker Compose files
│   └── docs/                    # Onboarding guides
├── monitoring/
│   ├── configs/                 # Alert rules, thresholds
│   ├── scripts/                 # Aggregation, cleanup
│   ├── packages/                # TypeScript packages
│   └── docs/                    # Observability guides
├── security/
│   ├── configs/                 # Policies
│   ├── scripts/                 # Rotation, scanning
│   ├── docs/                    # Runbooks
│   └── schemas/                 # JSON schemas
├── schemas/                     # Shared schemas
├── packages/                    # Shared TypeScript packages
├── tests/                       # Cross-domain tests
└── scripts/                     # Root-level scripts
```

## Base120 Transformations

This repo applies HUMMBL Base120 mental models:

| Code | Domain | Application |
|------|--------|-------------|
| P1 | Perspective | First principles framing |
| IN2 | Inversion | Premortem analysis |
| CO5 | Composition | Pipeline orchestration |
| DE3 | Decomposition | Modular scripts |
| RE2 | Recursion | Feedback loops |
| SY18 | Systems | Measurement & telemetry |

## Hard Rules

### Security
- **Never commit secrets** - Use `.gitignore`, secrets vault
- **Rotate immediately** - On any exposure
- **Scan pre-commit** - gitleaks required

### Development
- **Idempotent scripts** - Safe to re-run
- **Atomic operations** - Rollback on failure
- **Offline-first** - File-based storage preferred

### Documentation
- **Update runbooks** - After incidents
- **Reference Base120** - In implementation comments
- **Generate SITREPs** - At phase completion

## Gotchas

- Scripts must be executable: `chmod +x scripts/*.sh`
- Docker Compose profiles for optional services
- Secrets never in environment variables (use keychain/vault)
- All metrics in JSONL format for offline-first

## Dependencies

- Node 22+ (via fnm)
- pnpm 9+
- Docker/Colima
- gitleaks (for secret scanning)
- 1Password CLI (optional, for secrets)

## Related Repositories

- `/workspace/active/hummbl-agent/` - Source patterns for governance
- `/workspace/active/openclaw/` - Source patterns for CI/CD
- `~/.config/shell/` - Shell module patterns
