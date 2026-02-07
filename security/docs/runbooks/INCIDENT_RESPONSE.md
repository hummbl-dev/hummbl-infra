# Incident Response Runbook

**Classification**: Internal / Security Operations
**Version**: 1.0.0
**Last Updated**: 2026-02-07
**Base120 Models**: IN2 (premortem), IN10 (adversarial), SY1 (boundaries)

---

## 1. Purpose

This runbook provides step-by-step procedures for responding to security incidents affecting HUMMBL infrastructure. It covers detection, containment, eradication, recovery, and post-incident activities.

---

## 2. Severity Classification

### P1 - Critical (Respond within 15 minutes)

| Criteria | Examples |
|----------|----------|
| Active data breach | PII/credentials exfiltrated |
| Production systems compromised | Root access gained by attacker |
| Service-wide outage | All users affected |
| Regulatory notification required | GDPR/CCPA breach |

**Response Time**: 15 minutes acknowledgment, 1 hour containment
**Escalation**: Immediate to leadership + legal

### P2 - High (Respond within 1 hour)

| Criteria | Examples |
|----------|----------|
| Credential exposure | API keys leaked to public repo |
| Targeted attack detected | Brute force on admin accounts |
| Partial service impact | Key functionality degraded |
| Potential compliance impact | Audit trail gaps |

**Response Time**: 1 hour acknowledgment, 4 hour containment
**Escalation**: Security lead + affected system owners

### P3 - Medium (Respond within 4 hours)

| Criteria | Examples |
|----------|----------|
| Suspicious activity | Unusual login patterns |
| Vulnerability discovered | CVE in dependency |
| Policy violation | Unapproved access detected |
| Minor service impact | Non-critical feature affected |

**Response Time**: 4 hour acknowledgment, 24 hour resolution
**Escalation**: Security team

### P4 - Low (Respond within 24 hours)

| Criteria | Examples |
|----------|----------|
| Security improvement needed | Missing security headers |
| Informational finding | Scan detected outdated cert |
| Process improvement | Documentation gap |
| Training requirement | User security awareness |

**Response Time**: 24 hour acknowledgment, 1 week resolution
**Escalation**: Normal ticketing workflow

---

## 3. Escalation Matrix

### Contact Order by Severity

```
P1 Critical:
  1. On-call Engineer (primary)      -> PagerDuty/Slack @incident-critical
  2. Security Lead (5 min)           -> Phone + Slack
  3. Engineering Lead (15 min)       -> Phone + Slack
  4. Legal (if data breach, 30 min)  -> Email + Phone
  5. Executive (30 min)              -> Phone

P2 High:
  1. On-call Engineer                -> PagerDuty/Slack @incident-high
  2. Security Lead (30 min)          -> Slack
  3. System Owner (1 hour)           -> Slack

P3 Medium:
  1. Security Team                   -> Slack #security-incidents
  2. System Owner (4 hours)          -> Slack

P4 Low:
  1. Security Team                   -> Jira/Linear ticket
```

### Escalation Triggers

| Trigger | Action |
|---------|--------|
| No acknowledgment in SLA | Auto-escalate to next level |
| Incident scope expands | Re-classify severity |
| External party involved | Add legal to thread |
| Regulatory impact possible | Add compliance to thread |
| Media/social media exposure | Add communications to thread |

---

## 4. Incident Response Phases

### Phase 1: Detection & Triage (First 15 min)

**Objective**: Confirm incident, assign severity, notify stakeholders

#### Checklist

- [ ] **Confirm** incident is real (not false positive)
- [ ] **Classify** severity (P1-P4)
- [ ] **Create** incident record (see Section 7)
- [ ] **Notify** appropriate escalation path
- [ ] **Assign** Incident Commander (IC)
- [ ] **Open** communication channel (Slack #incident-YYYYMMDD-NN)

#### DO NOT

- DO NOT attempt remediation before containment assessment
- DO NOT delete logs or evidence
- DO NOT communicate externally without approval
- DO NOT assume scope is limited

### Phase 2: Containment (First 1 hour for P1)

**Objective**: Stop the bleeding, prevent further damage

#### Immediate Containment Actions

| Incident Type | Containment Action |
|--------------|-------------------|
| Credential leak | Rotate affected credentials immediately |
| Unauthorized access | Revoke sessions, disable accounts |
| Malware detected | Isolate affected systems |
| Data exfiltration | Block egress, preserve evidence |
| DDoS attack | Enable rate limiting, notify CDN |

#### Containment Checklist

- [ ] **Identify** affected systems and data
- [ ] **Isolate** compromised components (network segmentation)
- [ ] **Preserve** evidence (snapshots, logs)
- [ ] **Block** attack vector (firewall, WAF rules)
- [ ] **Rotate** potentially compromised credentials
- [ ] **Document** all containment actions with timestamps

#### Evidence Collection

```bash
# Create evidence directory
mkdir -p /tmp/incident-evidence-$(date +%Y%m%d-%H%M)

# Capture system state
ps aux > processes.txt
netstat -an > network.txt
last > logins.txt
cat /var/log/auth.log > auth.log

# Capture application logs
cp -r /var/log/application/ ./app-logs/

# Hash all evidence files
find . -type f -exec sha256sum {} \; > evidence-hashes.txt
```

### Phase 3: Eradication (Hours 1-4 for P1)

**Objective**: Remove threat, close attack vector

#### Eradication Checklist

- [ ] **Identify** root cause of incident
- [ ] **Remove** malware/backdoors from systems
- [ ] **Patch** vulnerability that was exploited
- [ ] **Reset** all potentially compromised credentials
- [ ] **Update** security controls to prevent recurrence
- [ ] **Verify** threat is eliminated

#### Common Eradication Actions

| Threat | Eradication Steps |
|--------|------------------|
| Compromised credentials | 1. Rotate all affected secrets 2. Revoke all sessions 3. Enable MFA if not present |
| Vulnerable dependency | 1. Upgrade to patched version 2. Audit for exploitation 3. Deploy to all environments |
| Misconfiguration | 1. Apply correct configuration 2. Add validation/monitoring 3. Update IaC templates |
| Malicious code | 1. Identify all affected files 2. Restore from clean backup 3. Scan for persistence |

### Phase 4: Recovery (Hours 4-24 for P1)

**Objective**: Restore normal operations, verify security

#### Recovery Checklist

- [ ] **Restore** affected systems from clean state
- [ ] **Verify** all security controls are functioning
- [ ] **Test** application functionality
- [ ] **Monitor** closely for recurrence
- [ ] **Gradually** remove containment measures
- [ ] **Confirm** with stakeholders before declaring resolved

#### Recovery Verification

```bash
# Verify no persistence mechanisms
# Check for suspicious scheduled tasks
crontab -l
ls -la /etc/cron.*

# Verify security controls
./scripts/doctor.sh
npm audit

# Run security scan
gitleaks detect --source . --verbose

# Verify authentication
# Test login flows, MFA, session management
```

### Phase 5: Post-Incident (Within 72 hours)

**Objective**: Learn from incident, improve defenses

#### Post-Incident Review Checklist

- [ ] **Schedule** post-mortem meeting (all stakeholders)
- [ ] **Prepare** incident timeline
- [ ] **Analyze** root cause (5 Whys)
- [ ] **Identify** process/control failures
- [ ] **Create** action items with owners and deadlines
- [ ] **Update** runbooks based on lessons learned
- [ ] **Share** sanitized findings with team

---

## 5. Communication Templates

### Internal Notification (P1/P2)

```
INCIDENT ALERT - P[X] - [Brief Description]

Status: [INVESTIGATING | CONTAINED | RESOLVED]
Incident ID: INC-YYYYMMDD-NN
Time Detected: [ISO timestamp]
Incident Commander: [Name]

SUMMARY:
[2-3 sentence description of what happened]

CURRENT IMPACT:
- [Affected systems/users]
- [Service degradation]

ACTIONS TAKEN:
- [Action 1]
- [Action 2]

NEXT UPDATE: [Time]

Join: #incident-YYYYMMDD-NN
```

### Status Update

```
INCIDENT UPDATE - INC-YYYYMMDD-NN

Status: [INVESTIGATING | CONTAINED | RESOLVED]
Time: [ISO timestamp]

PROGRESS SINCE LAST UPDATE:
- [Action completed]
- [Finding discovered]

CURRENT FOCUS:
- [What team is working on]

NEXT UPDATE: [Time or "When status changes"]
```

### Resolution Notification

```
INCIDENT RESOLVED - INC-YYYYMMDD-NN

Status: RESOLVED
Resolved At: [ISO timestamp]
Duration: [X hours, Y minutes]

SUMMARY:
[What happened and how it was resolved]

ROOT CAUSE:
[Brief root cause]

IMPACT:
- [Users/systems affected]
- [Duration of impact]

FOLLOW-UP:
- Post-mortem scheduled: [Date/Time]
- Action items: [X items in backlog]

Thank you to everyone who helped respond.
```

---

## 6. Special Procedures

### Credential Exposure Response

See: [SECRET_EXPOSURE_RESPONSE.md](./SECRET_EXPOSURE_RESPONSE.md)

### Regulatory Breach Notification

| Regulation | Notification Deadline | To Notify |
|------------|----------------------|-----------|
| GDPR | 72 hours | DPA + affected users |
| CCPA | "Without unreasonable delay" | Affected CA residents |
| HIPAA | 60 days | HHS + affected individuals |
| PCI-DSS | Immediately | Card brands + acquirer |

**Actions**:
1. Engage legal immediately
2. Document breach scope precisely
3. Prepare notification content
4. Execute notification plan

### Law Enforcement Involvement

**When to involve**:
- Criminal activity suspected
- Significant financial loss
- Nation-state threat indicators
- Regulatory requirement

**Process**:
1. Get legal approval first
2. Preserve all evidence (chain of custody)
3. Do NOT share technical details publicly
4. Assign single point of contact

---

## 7. Incident Record Schema

Each incident MUST have a record created:

```json
{
  "incident_id": "INC-YYYYMMDD-NN",
  "severity": "P1|P2|P3|P4",
  "status": "open|contained|resolved|closed",
  "title": "Brief description",
  "detected_at": "ISO-8601 timestamp",
  "detected_by": "how it was detected",
  "incident_commander": "name",
  "timeline": [
    {"time": "ISO-8601", "action": "description"}
  ],
  "affected_systems": ["system1", "system2"],
  "affected_data": ["data type if applicable"],
  "root_cause": "description (filled post-incident)",
  "resolution": "how it was resolved",
  "action_items": [
    {"item": "description", "owner": "name", "due": "date"}
  ]
}
```

Location: `/security/incidents/INC-YYYYMMDD-NN.json`

---

## 8. Tools & Resources

### Detection Tools

| Tool | Purpose | Location |
|------|---------|----------|
| gitleaks | Secret scanning | Pre-commit hook |
| npm audit | Dependency vulnerabilities | CI/CD pipeline |
| SIEM/logs | Anomaly detection | Centralized logging |

### Response Tools

| Tool | Purpose | Command |
|------|---------|---------|
| Secret rotation | Credential rotation | `./security/scripts/rotate-secret.sh` |
| Incident record | Create incident | `./security/scripts/create-incident.sh` |

### Reference Documents

- [RBAC Model](../RBAC_MODEL.md)
- [Secret Exposure Runbook](./SECRET_EXPOSURE_RESPONSE.md)
- [Compliance Matrix](../COMPLIANCE_MATRIX.md)

---

## 9. Training & Exercises

### Quarterly Activities

| Activity | Frequency | Participants |
|----------|-----------|--------------|
| Tabletop exercise | Quarterly | All engineers |
| Runbook review | Quarterly | Security team |
| Tool proficiency | Semi-annual | On-call rotation |

### Tabletop Scenarios

1. **Credential Leak**: API key published to public GitHub
2. **Insider Threat**: Employee downloads customer data
3. **Ransomware**: Production database encrypted
4. **Supply Chain**: Malicious dependency discovered

---

## 10. Continuous Improvement

### Metrics to Track

| Metric | Target | Current |
|--------|--------|---------|
| Mean time to detect (MTTD) | < 15 min | TBD |
| Mean time to contain (MTTC) | < 1 hour | TBD |
| Mean time to resolve (MTTR) | < 4 hours | TBD |
| Post-mortem completion | 100% | TBD |
| Action item completion | > 90% | TBD |

### Review Triggers

- After every P1/P2 incident
- Quarterly for runbook updates
- When new threat intelligence received
- When organizational changes occur

---

**Document Owner**: Security Team
**Review Cycle**: Quarterly
**Next Review**: Q2 2026
