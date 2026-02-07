# Security/Governance

RBAC documentation, secrets rotation, incident response, and compliance.

## Structure

```
security/
├── configs/
│   ├── rotation-policy.json
│   └── compliance-mapping.json
├── scripts/
│   ├── rotate-secret.sh
│   ├── check-secret-expiry.sh
│   ├── create-incident.sh
│   └── scan-secrets.sh
├── schemas/
│   └── incident-record.schema.json
├── docs/
│   ├── RBAC_MODEL.md
│   ├── COMPLIANCE_MATRIX.md
│   └── runbooks/
│       ├── INCIDENT_RESPONSE.md
│       └── SECRET_EXPOSURE_RESPONSE.md
└── tests/
    ├── secrets-exposure.test.mjs
    └── policy-enforcement.test.mjs
```

## Deliverables

- [ ] RBAC model documentation
- [ ] Secrets rotation script
- [ ] Secret expiry checker
- [ ] Incident response runbook
- [ ] Secret exposure runbook
- [ ] Compliance matrix
- [ ] Security test suite

## RBAC Model

4-way separation of duties:
```
propose → review → approve → execute
```

Roles:
- architect: propose, approve
- developer: propose, execute (if approved)
- reviewer: review, approve
- deployer: execute (if approved)
- auditor: view only

## Preset Profiles

| Profile | Audit | Separation |
|---------|-------|------------|
| flow | basic | none |
| balanced | full | propose_only |
| strict | signed | full_split |
| soc2 | external | approve_required |
| hipaa | external | full_split |
| lockdown | signed | full_split |

## Patterns

Based on research from:
- `/workspace/active/hummbl-agent/packages/governance/src/roles.ts`
- `/workspace/active/hummbl-agent/packages/governance/src/profile.ts`
