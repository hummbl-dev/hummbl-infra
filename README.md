# HUMMBL Infrastructure Platform

Unified infrastructure for the HUMMBL agent ecosystem.

## Quick Start

```bash
# Clone and enter
cd ~/hummbl-infra

# Run doctor to check prerequisites
./scripts/doctor.sh

# Full setup
./scripts/setup.sh
```

## Domains

### 1. CI/CD Pipeline (`ci-cd/`)

Container builds, multi-environment deployment, release automation.

**Key Deliverables:**
- [ ] Dockerfile (multi-stage, multi-arch)
- [ ] Container build workflow
- [ ] Environment configs (dev/staging/prod)
- [ ] Deploy workflow with rollback
- [ ] Release automation with signing

### 2. Development Environment (`dev-environment/`)

Setup automation, secrets management, local development stack.

**Key Deliverables:**
- [ ] Setup script suite (01-07)
- [ ] Secrets vault structure
- [ ] 1Password/keychain integration
- [ ] Docker Compose stack
- [ ] Doctor health check
- [ ] Onboarding documentation

### 3. Monitoring/Observability (`monitoring/`)

Metrics collection, aggregation, alerting, dashboards.

**Key Deliverables:**
- [ ] Metrics event schema
- [ ] Collector module
- [ ] Hourly/daily aggregator
- [ ] Alert rule engine
- [ ] Terminal dashboard
- [ ] Static HTML reports

### 4. Security/Governance (`security/`)

RBAC documentation, secrets rotation, incident response, compliance.

**Key Deliverables:**
- [ ] RBAC model documentation
- [ ] Secrets rotation script
- [ ] Incident response runbooks
- [ ] Compliance matrix
- [ ] Security test suite

## Implementation Roadmap

### Week 1-2: Foundation
- [ ] P0: Rotate exposed secrets
- [ ] P0: Add gitleaks pre-commit
- [ ] P1: Secrets vault structure
- [ ] P1: Incident response runbook

### Week 3-4: Developer Experience
- [ ] Setup automation scripts
- [ ] Doctor health check
- [ ] Docker Compose stack
- [ ] RBAC documentation

### Week 5-6: Observability
- [ ] Metrics schema
- [ ] Collector implementation
- [ ] Hourly aggregation
- [ ] Alert engine

### Week 7-8: CI/CD Automation
- [ ] Dockerfile
- [ ] Container build workflow
- [ ] Deploy workflow
- [ ] Release automation

## Research Artifacts

This repo was designed based on comprehensive research:

| Artifact | Location |
|----------|----------|
| Implementation Plan | `docs/infrastructure-plan.md` |
| Research Report | `docs/infrastructure-deep-dive-research.md` |
| SITREP | `docs/SITREP-2026-02-07.md` |

## Contributing

1. Follow Base120 transformations where applicable
2. Run `./scripts/lint-all.sh` before committing
3. Generate SITREP at phase completion
4. Update runbooks after incidents

## License

Internal use only.
