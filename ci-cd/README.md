# CI/CD Pipeline

Container builds, multi-environment deployment, and release automation.

## Structure

```
ci-cd/
├── configs/
│   ├── environments/
│   │   ├── dev.json
│   │   ├── staging.json
│   │   └── prod.json
│   └── signing/
├── scripts/
│   ├── build-container.sh
│   ├── deploy.sh
│   └── rollback.sh
├── workflows/
│   ├── build-container.yml
│   ├── deploy.yml
│   ├── release.yml
│   └── promote.yml
└── docs/
    └── deployment-guide.md
```

## Deliverables

- [x] Dockerfile (multi-stage, multi-arch)
- [x] build-container.yml workflow
- [x] Environment configs (dev/staging/prod)
- [x] deploy.yml with health checks
- [ ] release.yml with signing
- [x] rollback.sh script

## Patterns

Based on research from:
- `/workspace/active/openclaw/.github/workflows/docker-release.yml`
- `/workspace/active/hummbl-agent/.github/workflows/ci.yml`

## Industry Standards

- Target: SLSA Level 2+ compliance
- Container signing: cosign/sigstore
- SBOM generation: syft
