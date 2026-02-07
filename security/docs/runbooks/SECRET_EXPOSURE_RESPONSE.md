# Secret Exposure Response Runbook

**Classification**: Internal / Security Operations
**Version**: 1.0.0
**Last Updated**: 2026-02-07
**Base120 Models**: IN2 (premortem), IN10 (adversarial), DE3 (decomposition)

---

## 1. Purpose

This runbook provides specific procedures for responding to exposed secrets (API keys, passwords, tokens, certificates). Speed is critical - attackers actively scan for leaked credentials and can exploit them within minutes.

**Key Metric**: Detection to rotation should be < 1 hour for Tier 1 secrets.

---

## 2. Secret Tier Classification

### Tier 1 - Critical (Rotate within 1 hour)

| Secret Type | Examples | Impact if Exposed |
|-------------|----------|-------------------|
| Payment credentials | Stripe secret key, payment processor tokens | Financial fraud |
| Authentication secrets | JWT signing key, OAuth client secrets | Account takeover |
| Database credentials | Production DB password, connection strings | Data breach |
| Infrastructure | Cloud provider keys (AWS, GCP), SSH keys | Full compromise |

### Tier 2 - High (Rotate within 4 hours)

| Secret Type | Examples | Impact if Exposed |
|-------------|----------|-------------------|
| Third-party API keys | OpenAI, Anthropic, Twilio | Service abuse, cost |
| Internal service tokens | Inter-service auth tokens | Lateral movement |
| Monitoring credentials | Datadog, Sentry API keys | Observability gaps |
| CDN/Email credentials | Cloudflare, SendGrid keys | Service disruption |

### Tier 3 - Medium (Rotate within 24 hours)

| Secret Type | Examples | Impact if Exposed |
|-------------|----------|-------------------|
| Development API keys | Test environment keys | Limited blast radius |
| Analytics credentials | Analytics service tokens | Data leakage |
| Logging credentials | Log aggregation tokens | Log access |

### Tier 4 - Low (Rotate within 72 hours)

| Secret Type | Examples | Impact if Exposed |
|-------------|----------|-------------------|
| Public API keys | Google Maps (client-side) | Quota abuse |
| Demo credentials | Sandbox environment | Minimal impact |
| Expired credentials | Already rotated secrets | None if rotated |

---

## 3. Detection Sources

### Automated Detection

| Source | Response Time | Action |
|--------|---------------|--------|
| GitHub Secret Scanning | Near real-time | Auto-alert to Slack |
| gitleaks (pre-commit) | Before commit | Block commit |
| Trufflehog (CI) | On PR | Block merge |
| AWS GuardDuty | Minutes | Alert + auto-remediate |
| 1Password Watchtower | Daily | Manual review |

### Manual Detection

| Source | Typical Discovery |
|--------|-------------------|
| Code review | During PR review |
| Security audit | Periodic scanning |
| Penetration test | External assessment |
| Bug bounty | External report |
| Employee report | Self-disclosure |

---

## 4. Immediate Response (First 15 Minutes)

### Step 1: Confirm Exposure

```bash
# Verify the secret is actually exposed (not a false positive)
# Check if it matches a known secret pattern

# For git history exposure:
git log -p --all -S 'EXPOSED_SECRET_VALUE' --since="1 week ago"

# For file exposure:
grep -r "EXPOSED_SECRET_VALUE" .
```

**Decision Tree**:
- Is this a real secret? (not example/placeholder) -> Continue
- Was it pushed to a public repo? -> Severity increases
- Is the secret still valid/active? -> If rotated, lower priority
- What tier is this secret? -> Determines timeline

### Step 2: Classify and Escalate

| If Tier | Then |
|---------|------|
| Tier 1 | IMMEDIATELY notify security lead + begin rotation |
| Tier 2 | Notify security team + begin rotation within 1 hour |
| Tier 3 | Create incident ticket + schedule rotation |
| Tier 4 | Create ticket for next business day |

### Step 3: Document (Do NOT skip)

Create incident record BEFORE rotation:

```bash
# Create incident record
./security/scripts/create-incident.sh \
  --type secret-exposure \
  --severity P2 \
  --secret-name "OPENAI_API_KEY" \
  --exposure-vector "git-history"
```

---

## 5. Rotation Procedure

### Using the Rotation Script

```bash
# Standard rotation (interactive)
./security/scripts/rotate-secret.sh OPENAI_API_KEY

# Force rotation (no confirmation)
./security/scripts/rotate-secret.sh -f -t 1 STRIPE_SECRET_KEY

# Rotation with 1Password store
./security/scripts/rotate-secret.sh -s 1password DATABASE_PASSWORD

# Dry run (see what would happen)
./security/scripts/rotate-secret.sh -n ANTHROPIC_API_KEY
```

### Manual Rotation by Provider

#### OpenAI
```
1. Go to: https://platform.openai.com/api-keys
2. Click "Create new secret key"
3. Delete the compromised key
4. Update all services with new key
```

#### Anthropic
```
1. Go to: https://console.anthropic.com/settings/keys
2. Create new API key
3. Delete the compromised key
4. Update all services with new key
```

#### Stripe
```
1. Go to: https://dashboard.stripe.com/apikeys
2. Roll the secret key (creates new, keeps old active briefly)
3. Update all services with new key
4. Confirm old key is disabled
```

#### AWS
```bash
# Rotate IAM access key
aws iam create-access-key --user-name USERNAME
# Update all services
aws iam delete-access-key --user-name USERNAME --access-key-id OLD_KEY_ID
```

#### GitHub (Personal Access Token)
```
1. Go to: https://github.com/settings/tokens
2. Delete compromised token
3. Generate new token with same scopes
4. Update all services
```

#### Supabase
```
1. Go to: Project Settings > API
2. Regenerate anon/service_role key
3. Update all services
4. Verify connections work
```

### Rotation Order (Multi-Secret Exposure)

When multiple secrets are exposed, rotate in this order:

```
1. Infrastructure (AWS, GCP, cloud providers)
   └── These provide access to rotate everything else

2. Database credentials
   └── Protect data first

3. Payment/Financial credentials
   └── Prevent financial fraud

4. Authentication secrets (JWT, OAuth)
   └── Prevent account takeover

5. Third-party API keys
   └── Prevent abuse

6. Internal service tokens
   └── Complete the rotation
```

---

## 6. Verification Procedure

After rotation, VERIFY the change is effective:

### Step 1: Confirm New Secret Works

```bash
# Test new secret (example for OpenAI)
curl https://api.openai.com/v1/models \
  -H "Authorization: Bearer $NEW_OPENAI_API_KEY" \
  | jq '.data[0].id'

# Expected: Returns model ID
# If error: Rollback immediately
```

### Step 2: Confirm Old Secret is Invalid

```bash
# Test old secret is rejected
curl https://api.openai.com/v1/models \
  -H "Authorization: Bearer $OLD_OPENAI_API_KEY" \
  2>&1

# Expected: 401 Unauthorized
# If success: SECRET NOT PROPERLY ROTATED - escalate
```

### Step 3: Verify Service Functionality

```bash
# Run application health checks
./scripts/doctor.sh

# Run integration tests
npm test -- --grep "integration"

# Check logs for auth errors
tail -f /var/log/application.log | grep -i "auth\|401\|403"
```

---

## 7. Cleanup Procedure

### Remove from Git History (If Pushed)

**WARNING**: This rewrites history. Coordinate with team first.

```bash
# Option 1: BFG Repo Cleaner (recommended for large repos)
java -jar bfg.jar --replace-text passwords.txt repo.git
cd repo.git
git reflog expire --expire=now --all
git gc --prune=now --aggressive

# Option 2: git-filter-repo (for smaller repos)
git filter-repo --replace-text expressions.txt

# Option 3: For single file (simple cases)
git filter-branch --force --index-filter \
  'git rm --cached --ignore-unmatch path/to/file' \
  --prune-empty --tag-name-filter cat -- --all
```

### Force Push and Notify

```bash
# Force push cleaned history
git push --force --all
git push --force --tags

# Notify team
# "Git history was rewritten to remove exposed secret.
#  Everyone needs to re-clone or reset their local repos."
```

### Invalidate Caches

| Service | Cache Invalidation |
|---------|-------------------|
| GitHub | Automatic on force push |
| GitLab | Automatic on force push |
| CI/CD | Clear build caches |
| CDN | Purge if served |
| Search engines | Request removal (if indexed) |

---

## 8. Post-Exposure Actions

### Audit for Abuse (Within 24 hours)

Check if the exposed secret was used maliciously:

| Provider | Audit Location |
|----------|----------------|
| OpenAI | Usage dashboard, billing |
| AWS | CloudTrail logs |
| Stripe | Dashboard > Developers > Logs |
| GitHub | Security > Audit log |
| Supabase | Dashboard > Logs |

```bash
# AWS: Check for unusual API calls
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=Username,AttributeValue=EXPOSED_USER \
  --start-time "2024-01-01T00:00:00Z"

# Look for:
# - Unusual regions
# - New resources created
# - Data access patterns
```

### Update Preventive Controls

After each exposure, review:

- [ ] Was this caught by pre-commit hook? If not, why?
- [ ] Was the secret in `.gitignore`? If not, add pattern
- [ ] Was there a `.env.example` that could have been used instead?
- [ ] Do we need additional secret scanning rules?

### Add to Secret Scanning Rules

```yaml
# .gitleaks.toml - add patterns for similar secrets
[[rules]]
  description = "Custom API Key Pattern"
  regex = '''PATTERN_THAT_WOULD_HAVE_CAUGHT_THIS'''
  tags = ["custom", "api-key"]
```

---

## 9. Prevention Checklist

### Developer Practices

- [ ] Never hardcode secrets in source code
- [ ] Use `.env.example` with placeholders
- [ ] Use secret managers (1Password, Vault, AWS Secrets Manager)
- [ ] Review diffs before committing
- [ ] Enable GitHub secret scanning

### Repository Configuration

```bash
# .gitignore entries (required)
.env
.env.local
.env.*.local
*.pem
*.key
secrets/
.secrets/

# .gitleaks.toml (required)
# Configure secret patterns

# pre-commit hook (required)
# Run gitleaks before every commit
```

### CI/CD Configuration

```yaml
# In CI pipeline
- name: Scan for secrets
  run: gitleaks detect --source . --verbose
  if: always()  # Run even if other steps fail
```

---

## 10. Rollback Procedure

If rotation causes service disruption:

```bash
# View available rollbacks
ls -la /path/to/_state/audit/secrets/.rollback-*

# Rollback specific rotation
./security/scripts/rotate-secret.sh --rollback rot-1234567890-12345
```

### Rollback Decision Tree

```
Service broken after rotation?
├── Yes
│   ├── Is it a configuration issue? -> Fix config, don't rollback
│   ├── Is new secret invalid? -> Investigate, may need to re-generate
│   └── Is old secret still compromised? -> DO NOT rollback, fix forward
└── No
    └── Continue monitoring
```

---

## 11. Metrics and Reporting

### Track After Every Incident

| Metric | Target | Record In |
|--------|--------|-----------|
| Time to detect | < 5 min | Incident record |
| Time to rotation start | < 15 min | Incident record |
| Time to rotation complete | < 1 hour (Tier 1) | Incident record |
| Services impacted | 0 | Incident record |
| Abuse detected | 0 | Incident record |

### Monthly Review

- Number of secret exposures
- Detection source breakdown
- Average response time by tier
- Preventive control gaps identified

---

## 12. Quick Reference

### Emergency Contacts

| Role | Contact |
|------|---------|
| Security Lead | @security-lead (Slack) |
| On-Call | PagerDuty |
| Legal (if breach) | legal@company.com |

### Commands Cheat Sheet

```bash
# Rotate secret
./security/scripts/rotate-secret.sh SECRET_NAME

# Force rotate (no confirmation)
./security/scripts/rotate-secret.sh -f SECRET_NAME

# Check if secret exists
./security/scripts/rotate-secret.sh -v SECRET_NAME

# Rollback rotation
./security/scripts/rotate-secret.sh --rollback ROTATION_ID

# Scan for secrets in codebase
gitleaks detect --source . --verbose

# Scan git history
gitleaks detect --source . --log-opts="--all" --verbose
```

### Response Timeline (Tier 1)

```
00:00 - Secret exposed
00:05 - Detection + classification (max)
00:10 - Incident created + escalated
00:15 - Rotation started
00:30 - Rotation complete
00:45 - Verification complete
01:00 - Services confirmed working
04:00 - Abuse audit complete
24:00 - Post-incident review scheduled
```

---

**Document Owner**: Security Team
**Review Cycle**: Quarterly
**Next Review**: Q2 2026
