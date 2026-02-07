# HUMMBL Infrastructure Implementation Plan

**Generated**: 2026-02-07
**Scope**: CI/CD, Development Environment, Monitoring/Observability, Security/Governance
**Base120 Transformations Applied**: P1, P2, IN2, IN10, CO5, DE3, RE2, SY1, SY3, SY18

---

## Executive Summary

This plan addresses four infrastructure domains for the HUMMBL workspace:

| Domain | Current Maturity | Target | Key Deliverables |
|--------|------------------|--------|------------------|
| CI/CD | 30% | 80% | Deployment automation, multi-env promotion, container builds |
| Dev Environment | 60% | 90% | Setup automation, secrets vault, Docker Compose stack |
| Monitoring | 25% | 75% | Metrics collection, dashboards, alerting |
| Security/Governance | 75% | 95% | RBAC docs, secrets rotation, incident runbooks |

---

## Phase Dependencies

```
                    ┌─────────────────────────────────────────────────────────────┐
                    │                  INFRASTRUCTURE PLAN                         │
                    └─────────────────────────────────────────────────────────────┘
                                              │
          ┌───────────────────────────────────┼───────────────────────────────────┐
          │                                   │                                   │
          ▼                                   ▼                                   ▼
┌─────────────────────┐            ┌─────────────────────┐            ┌─────────────────────┐
│ SECURITY/GOVERNANCE │            │   DEV ENVIRONMENT   │            │   MONITORING/OBS    │
│  (Foundation Layer) │            │  (Developer Layer)  │            │  (Insight Layer)    │
│                     │            │                     │            │                     │
│ • Secrets rotation  │──────────▶ │ • Secrets vault     │            │ • Metrics schema    │
│ • Incident runbooks │            │ • Setup automation  │            │ • Offline collection│
│ • RBAC docs         │            │ • Docker Compose    │            │ • Alerting          │
└─────────────────────┘            └─────────────────────┘            └─────────────────────┘
          │                                   │                                   │
          │                                   │                                   │
          ▼                                   ▼                                   ▼
          └───────────────────────────────────┼───────────────────────────────────┘
                                              │
                                              ▼
                                   ┌─────────────────────┐
                                   │       CI/CD         │
                                   │  (Delivery Layer)   │
                                   │                     │
                                   │ • Container builds  │
                                   │ • Multi-env deploy  │
                                   │ • Release automation│
                                   └─────────────────────┘
```

---

## Domain 1: Security/Governance (Priority: CRITICAL)

### Using P1 (First Principles Framing)
The security layer must be addressed first because all other domains depend on secure secrets management and governance patterns.

### Deliverables

| # | Deliverable | Location | Effort |
|---|-------------|----------|--------|
| 1.1 | RBAC Model Documentation | `docs/RBAC_MODEL.md` | Medium |
| 1.2 | Secrets Rotation Script | `scripts/rotate-secret.sh` | High |
| 1.3 | Secret Expiry Checker | `scripts/check-secret-expiry.sh` | Medium |
| 1.4 | Rotation Policy | `configs/rotation-policy.json` | Low |
| 1.5 | Incident Response Runbook | `docs/runbooks/INCIDENT_RESPONSE.md` | Medium |
| 1.6 | Secret Exposure Runbook | `docs/runbooks/SECRET_EXPOSURE_RESPONSE.md` | Medium |
| 1.7 | Incident Record Schema | `schemas/incident_record.schema.json` | Low |
| 1.8 | Security Test Suite | `tests/security/` | High |
| 1.9 | Compliance Matrix | `docs/COMPLIANCE_MATRIX.md` | Medium |

### Using IN2 (Premortem Analysis)
**What could go wrong?**
- Secret exposure in logs → Mitigate with noLogging policy enforcement
- Rotation failure mid-process → Mitigate with atomic rotation with rollback
- Incident miscategorization → Mitigate with clear severity definitions

### Using IN10 (Red Team Thinking)
Attack vectors to address:
- Prompt injection to bypass governance → Existing Universal Hardening Preamble
- Credential leakage in artifacts → lint-secret-scan.sh in CI
- Privilege escalation → RBAC enforcement at governor level

---

## Domain 2: Development Environment

### Using DE3 (Decomposition)
Break setup into atomic, testable scripts:

```
scripts/setup/
├── setup.sh              # Master orchestrator
├── 01-system-check.sh    # Verify prerequisites
├── 02-install-deps.sh    # Homebrew, node, pnpm
├── 03-configure-shell.sh # Shell modules
├── 04-setup-docker.sh    # Colima + Docker context
├── 05-setup-git.sh       # Git config, hooks
├── 06-setup-secrets.sh   # Vault initialization
├── 07-verify-install.sh  # Doctor checks
└── lib/
    ├── colors.sh
    ├── prompts.sh
    └── checks.sh
```

### Deliverables

| # | Deliverable | Location | Effort |
|---|-------------|----------|--------|
| 2.1 | Secrets Vault Structure | `.secrets.vault/` | Medium |
| 2.2 | 1Password/Doppler Integration | `.config/shell/06-secrets.zsh` | High |
| 2.3 | Master Setup Script | `scripts/setup/setup.sh` | High |
| 2.4 | Doctor Script | `scripts/doctor.sh` | Medium |
| 2.5 | Docker Compose Stack | `docker/docker-compose.yml` | Medium |
| 2.6 | Enhanced Pre-commit Hook | `.git-hooks/pre-commit` | Low |
| 2.7 | Onboarding Documentation | `DOCUMENTATION/onboarding/` | Medium |

### Using CO5 (Integration)
Docker Compose services to integrate:
- PostgreSQL 16 (database)
- Redis 7 (cache)
- Ollama (local LLM, optional profile)
- Qdrant (vector DB, optional profile)

---

## Domain 3: Monitoring/Observability

### Using SY18 (Measurement & Telemetry)
Instrumentation points:
1. `scripts/run-cmd.sh` - Command entry/exit
2. `packages/router/` - Routing decisions
3. `packages/control-plane/` - Governance decisions
4. `scripts/cost-control.py` - Budget transitions

### Deliverables

| # | Deliverable | Location | Effort |
|---|-------------|----------|--------|
| 3.1 | Metrics Event Schema | `schemas/metrics-event.schema.json` | Low |
| 3.2 | Metrics Collector | `packages/observability/src/collector.ts` | High |
| 3.3 | File Metrics Sink | `packages/observability/src/sinks/file-sink.ts` | Medium |
| 3.4 | Daily Aggregator | `packages/observability/src/aggregator.ts` | Medium |
| 3.5 | Alert Evaluator | `packages/observability/src/alert-evaluator.ts` | Medium |
| 3.6 | Enhanced Dashboard | `dashboard.js` (modify) | Medium |
| 3.7 | Metrics Cleanup Script | `scripts/metrics-cleanup.sh` | Low |
| 3.8 | Alert Configuration | `configs/budget-alerts.json` (expand) | Low |

### Using RE2 (Feedback Loops)
The observability system observes itself:
- Metric collection latency tracking
- Alert effectiveness measurement
- Storage growth rate alerting

### Offline-First Constraint
All metrics stored locally in `_state/metrics/YYYY-MM-DD.jsonl` with optional sync.

---

## Domain 4: CI/CD Pipeline

### Using CO10 (Pipeline Orchestration)

```
PR Flow:
classify ──► code-checks ──► guardrails ──► preview-deploy

Release Flow:
tag ──► build-images ──► sign ──► registry-push ──► deploy-prod
          │                  │              │
          ▼                  ▼              ▼
    multi-arch          cosign         ghcr.io
    (amd64/arm64)       attestation
```

### Deliverables

| # | Deliverable | Location | Effort |
|---|-------------|----------|--------|
| 4.1 | Dockerfile | `Dockerfile` | Medium |
| 4.2 | Container Build Workflow | `.github/workflows/build-container.yml` | High |
| 4.3 | Environment Configs | `configs/environments/{dev,staging,prod}.json` | Low |
| 4.4 | Deploy Workflow | `.github/workflows/deploy.yml` | High |
| 4.5 | Release Workflow | `.github/workflows/release.yml` | High |
| 4.6 | Promote Workflow | `.github/workflows/promote.yml` | Medium |
| 4.7 | Rollback Workflow | `.github/workflows/rollback.yml` | Medium |
| 4.8 | Version Bump Workflow | `.github/workflows/version-bump.yml` | Medium |
| 4.9 | Deployment Config Lint | `scripts/lint-deployment-config.sh` | Low |

### Using SY14 (Risk & Resilience)
- Immutable artifacts (container digests)
- Automated rollback triggers
- Health check gates before traffic shift

---

## Implementation Sequence

### Week 1-2: Foundation (Security + Dev Environment Start)
```
// Using P1 (First Principles) - Start with security foundation
const week1 = [
  "1.5: Incident Response Runbook",      // Learn from recent incident
  "1.6: Secret Exposure Runbook",        // Codify rotation process
  "1.7: Incident Record Schema",         // Standardize tracking
  "2.1: Secrets Vault Structure",        // Prepare for migration
];

const week2 = [
  "1.2: Secrets Rotation Script",        // Automate what was manual
  "1.3: Secret Expiry Checker",          // Proactive alerting
  "1.4: Rotation Policy",                // Governance
  "2.2: 1Password Integration",          // Secure secrets
];
```

### Week 3-4: Developer Experience
```
// Using DE3 (Decomposition) - Atomic setup scripts
const week3 = [
  "2.3: Master Setup Script",            // Orchestrator
  "2.4: Doctor Script",                  // Self-healing
  "2.6: Enhanced Pre-commit Hook",       // Guard rails
];

const week4 = [
  "2.5: Docker Compose Stack",           // Local services
  "2.7: Onboarding Documentation",       // Developer enablement
  "1.1: RBAC Model Documentation",       // Complete governance docs
];
```

### Week 5-6: Observability
```
// Using SY18 (Telemetry) - Instrument everything
const week5 = [
  "3.1: Metrics Event Schema",           // Contract first
  "3.2: Metrics Collector",              // Core collection
  "3.3: File Metrics Sink",              // Offline-first storage
];

const week6 = [
  "3.4: Daily Aggregator",               // Roll-ups
  "3.5: Alert Evaluator",                // Threshold checks
  "3.8: Alert Configuration",            // Expand thresholds
  "3.6: Enhanced Dashboard",             // Visualization
];
```

### Week 7-8: CI/CD Automation
```
// Using CO10 (Pipeline Orchestration) - End-to-end delivery
const week7 = [
  "4.1: Dockerfile",                     // Container definition
  "4.2: Container Build Workflow",       // Build automation
  "4.3: Environment Configs",            // Per-env settings
  "4.4: Deploy Workflow",                // Deployment automation
];

const week8 = [
  "4.5: Release Workflow",               // Version -> Deploy
  "4.6: Promote Workflow",               // Environment promotion
  "4.7: Rollback Workflow",              // Failure recovery
  "1.8: Security Test Suite",            // CI security gates
  "1.9: Compliance Matrix",              // Compliance tracking
];
```

---

## Risk Matrix

| Risk | Domain | Probability | Impact | Mitigation | Base120 |
|------|--------|-------------|--------|------------|---------|
| Secret exposure during rotation | Security | Medium | Critical | Atomic rotation with rollback | IN2 |
| Setup script failure | Dev Env | Low | Low | Atomic scripts, doctor verification | DE3 |
| Metrics data bloat | Monitoring | High | Medium | Retention policy, cleanup automation | SY18 |
| Deployment rollback failure | CI/CD | Low | High | Immutable digests, artifact retention | SY14 |
| Alert fatigue | Monitoring | Medium | Medium | Threshold tuning, cooldown periods | RE2 |

---

## Success Criteria

### Security/Governance
- [ ] All secrets have rotation dates in registry
- [ ] `check-secret-expiry.sh` runs in CI
- [ ] Incident runbooks reviewed and tested
- [ ] RBAC model documented and validated

### Development Environment
- [ ] New developer completes setup in <30 minutes
- [ ] `scripts/doctor.sh` passes on fresh install
- [ ] Docker Compose stack starts with single command
- [ ] No plaintext secrets in environment files

### Monitoring/Observability
- [ ] All governed commands emit metrics
- [ ] Daily aggregation produces valid reports
- [ ] Alerts trigger at defined thresholds
- [ ] Dashboard displays real-time data

### CI/CD
- [ ] Container builds succeed for multi-arch
- [ ] Images push to GHCR with signed attestations
- [ ] Deploy workflow completes for all environments
- [ ] Rollback executes in <5 minutes

---

## Files to Create/Modify Summary

### New Files (35)
```
# Security/Governance
docs/RBAC_MODEL.md
docs/runbooks/INCIDENT_RESPONSE.md
docs/runbooks/SECRET_EXPOSURE_RESPONSE.md
docs/COMPLIANCE_MATRIX.md
schemas/incident_record.schema.json
configs/rotation-policy.json
scripts/rotate-secret.sh
scripts/check-secret-expiry.sh
scripts/create-incident.sh
tests/security/secrets-exposure.test.mjs
tests/security/policy-enforcement.test.mjs
tests/security/governor-decision.test.mjs

# Development Environment
.secrets.vault/README.md
.secrets.vault/templates/*.env.template
scripts/setup/setup.sh
scripts/setup/01-system-check.sh
scripts/setup/02-install-deps.sh
scripts/setup/03-configure-shell.sh
scripts/setup/04-setup-docker.sh
scripts/setup/05-setup-git.sh
scripts/setup/06-setup-secrets.sh
scripts/setup/07-verify-install.sh
scripts/doctor.sh
docker/docker-compose.yml
DOCUMENTATION/onboarding/*.md

# Monitoring/Observability
packages/observability/package.json
packages/observability/src/collector.ts
packages/observability/src/aggregator.ts
packages/observability/src/alert-evaluator.ts
schemas/metrics-event.schema.json
scripts/metrics-cleanup.sh

# CI/CD
Dockerfile
.github/workflows/build-container.yml
.github/workflows/deploy.yml
.github/workflows/release.yml
.github/workflows/promote.yml
.github/workflows/rollback.yml
.github/workflows/version-bump.yml
configs/environments/dev.json
configs/environments/staging.json
configs/environments/prod.json
scripts/lint-deployment-config.sh
```

### Files to Modify (8)
```
.config/shell/06-secrets.zsh          # 1Password integration
.git-hooks/pre-commit                 # Enhanced hooks
.github/workflows/ci.yml              # Security tests + compliance
configs/budget-alerts.json            # Expanded alert thresholds
configs/secrets-registry.yaml         # Rotation tracking
dashboard.js                          # Enhanced metrics display
packages/router/src/base120/telemetry.ts  # Metrics bridge
scripts/run-cmd.sh                    # Metrics emission
```

---

## Next Steps

1. **Approve this plan** - Review phases, dependencies, and deliverables
2. **Prioritize immediate actions** - Secrets rotation (learn from recent incident)
3. **Assign ownership** - Per-phase or per-deliverable
4. **Begin Phase 1** - Security/Governance foundation

---

*Plan generated using Base120 transformations: P1 (First Principles), P2 (Stakeholder Mapping), IN2 (Premortem), IN10 (Red Team), CO5 (Pipeline), CO10 (Orchestration), DE3 (Decomposition), RE2 (Feedback Loops), SY1 (Boundaries), SY14 (Resilience), SY18 (Telemetry)*
