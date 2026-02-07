# RBAC Model Documentation

**Classification**: Internal / Security Architecture
**Version**: 1.0.0
**Last Updated**: 2026-02-07
**Base120 Models**: P2 (stakeholder), SY1 (boundaries), IN10 (adversarial)

---

## 1. Overview

This document defines the Role-Based Access Control (RBAC) model for HUMMBL infrastructure. The model implements a 4-way separation of duties pattern to prevent single points of compromise and ensure auditability.

### Core Principle

```
No single role can complete a sensitive action alone.
propose -> review -> approve -> execute
```

---

## 2. Role Definitions

### 2.1 Architect

**Purpose**: System design and high-level approval authority

| Capability | Allowed | Rationale |
|------------|---------|-----------|
| can_propose | Yes | Can propose architectural changes |
| can_review | No | Separation from review function |
| can_approve | Yes | Final authority on architecture |
| can_execute | No | Prevents self-approval + execution |
| can_view | Yes | Full visibility for decisions |

**Typical Holders**: Senior engineers, tech leads
**Restrictions**: Cannot review own proposals, cannot execute changes

### 2.2 Developer

**Purpose**: Implementation and execution of approved changes

| Capability | Allowed | Rationale |
|------------|---------|-----------|
| can_propose | Yes | Can propose code changes |
| can_review | No | Separation from review |
| can_approve | No | Requires external approval |
| can_execute | Yes | Can execute approved changes |
| can_view | Yes | Visibility into own domain |

**Typical Holders**: Software engineers, contractors
**Restrictions**: Cannot approve own work, execution requires prior approval

### 2.3 Reviewer

**Purpose**: Code review and quality assurance

| Capability | Allowed | Rationale |
|------------|---------|-----------|
| can_propose | No | Separation from authorship |
| can_review | Yes | Primary review function |
| can_approve | Yes | Can approve after review |
| can_execute | No | Separation from execution |
| can_view | Yes | Full visibility for review |

**Typical Holders**: Senior engineers, security engineers
**Restrictions**: Cannot propose changes (would review own work)

### 2.4 Deployer

**Purpose**: Production deployment execution

| Capability | Allowed | Rationale |
|------------|---------|-----------|
| can_propose | No | Separation from authorship |
| can_review | No | Separation from review |
| can_approve | No | Separation from approval |
| can_execute | Yes | Focused execution authority |
| can_view | Yes | Operational visibility |

**Typical Holders**: DevOps engineers, SREs, CI/CD systems
**Restrictions**: Can only execute pre-approved changes

### 2.5 Auditor

**Purpose**: Compliance verification and audit trail review

| Capability | Allowed | Rationale |
|------------|---------|-----------|
| can_propose | No | Independence from changes |
| can_review | No | Independence from workflow |
| can_approve | No | Independence from decisions |
| can_execute | No | Read-only access |
| can_view | Yes | Complete audit visibility |

**Typical Holders**: Compliance officers, external auditors, security reviewers
**Restrictions**: Pure read-only access for independence

---

## 3. Permission Matrix

### 3.1 Capability by Role

| Role | Propose | Review | Approve | Execute | View |
|------|---------|--------|---------|---------|------|
| architect | X | - | X | - | X |
| developer | X | - | - | X | X |
| reviewer | - | X | X | - | X |
| deployer | - | - | - | X | X |
| auditor | - | - | - | - | X |

### 3.2 Resource by Role

| Resource | architect | developer | reviewer | deployer | auditor |
|----------|-----------|-----------|----------|----------|---------|
| Production config | propose, approve | - | review, approve | execute | view |
| Code changes | propose, approve | propose, execute | review, approve | - | view |
| Secret rotation | propose, approve | - | review, approve | execute | view |
| Incident response | approve | execute | - | execute | view |
| Audit logs | view | view | view | view | view |
| User management | propose, approve | - | review | execute | view |

---

## 4. Separation of Duties

### 4.1 Four-Way Separation

The RBAC model enforces separation across four distinct phases:

```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│ PROPOSE  │ -> │  REVIEW  │ -> │ APPROVE  │ -> │ EXECUTE  │
│          │    │          │    │          │    │          │
│ architect│    │ reviewer │    │ reviewer │    │ developer│
│ developer│    │          │    │ architect│    │ deployer │
└──────────┘    └──────────┘    └──────────┘    └──────────┘
```

### 4.2 Conflict Detection

The system MUST prevent these conflict scenarios:

| Conflict | Detection Rule |
|----------|----------------|
| Self-approval | proposer.id != approver.id |
| Review own code | author.id != reviewer.id |
| Approve own proposal | proposer.id != approver.id |
| Execute unapproved | approval.exists AND approval.valid |

### 4.3 Minimum Participants

| Action Type | Minimum Distinct Actors | Required Roles |
|-------------|------------------------|----------------|
| Code change (standard) | 2 | developer + reviewer |
| Code change (security) | 3 | developer + reviewer + architect |
| Production deploy | 2 | approver + deployer |
| Secret rotation | 2 | architect + deployer |
| Emergency change | 2 | (any 2 with can_execute) |

---

## 5. Preset Profiles

Profiles provide pre-configured RBAC settings for different operational contexts.

### 5.1 Profile Comparison

| Profile | Audit Level | Separation | Use Case |
|---------|-------------|------------|----------|
| flow | basic | none | Maximum autonomy, development |
| balanced | full | propose_only | Standard daily operations |
| strict | signed | full_split | Security-sensitive changes |
| soc2 | external | approve_required | SOC 2 compliance |
| hipaa | external | full_split | Healthcare data handling |
| lockdown | signed | full_split | Code freeze, incident response |

### 5.2 Profile Definitions

#### flow
```json
{
  "name": "flow",
  "description": "Maximum autonomy for rapid development",
  "audit": {
    "level": "basic",
    "signing": false,
    "retention_days": 30
  },
  "separation": {
    "type": "none",
    "self_approval_allowed": true,
    "minimum_reviewers": 0
  },
  "restrictions": {
    "production_changes": false,
    "secret_access": false,
    "time_based": false
  }
}
```

#### balanced
```json
{
  "name": "balanced",
  "description": "Standard operations with basic controls",
  "audit": {
    "level": "full",
    "signing": false,
    "retention_days": 90
  },
  "separation": {
    "type": "propose_only",
    "self_approval_allowed": false,
    "minimum_reviewers": 1
  },
  "restrictions": {
    "production_changes": true,
    "secret_access": false,
    "time_based": false
  }
}
```

#### strict
```json
{
  "name": "strict",
  "description": "Enhanced controls for sensitive operations",
  "audit": {
    "level": "full",
    "signing": true,
    "retention_days": 365
  },
  "separation": {
    "type": "full_split",
    "self_approval_allowed": false,
    "minimum_reviewers": 2
  },
  "restrictions": {
    "production_changes": true,
    "secret_access": true,
    "time_based": true
  }
}
```

#### soc2
```json
{
  "name": "soc2",
  "description": "SOC 2 Type II compliance requirements",
  "audit": {
    "level": "external",
    "signing": true,
    "retention_days": 730,
    "external_backup": true
  },
  "separation": {
    "type": "approve_required",
    "self_approval_allowed": false,
    "minimum_reviewers": 1,
    "approval_required_for": ["production", "secrets", "user_data"]
  },
  "restrictions": {
    "production_changes": true,
    "secret_access": true,
    "time_based": true,
    "change_window": "business_hours"
  }
}
```

#### hipaa
```json
{
  "name": "hipaa",
  "description": "HIPAA compliance for PHI handling",
  "audit": {
    "level": "external",
    "signing": true,
    "retention_days": 2190,
    "external_backup": true,
    "phi_access_logging": true
  },
  "separation": {
    "type": "full_split",
    "self_approval_allowed": false,
    "minimum_reviewers": 2,
    "approval_required_for": ["all"]
  },
  "restrictions": {
    "production_changes": true,
    "secret_access": true,
    "time_based": true,
    "phi_encryption_required": true,
    "break_glass_procedure": true
  }
}
```

#### lockdown
```json
{
  "name": "lockdown",
  "description": "Emergency freeze - minimal changes allowed",
  "audit": {
    "level": "full",
    "signing": true,
    "retention_days": 365,
    "real_time_notification": true
  },
  "separation": {
    "type": "full_split",
    "self_approval_allowed": false,
    "minimum_reviewers": 2,
    "emergency_override_required": true
  },
  "restrictions": {
    "production_changes": true,
    "secret_access": true,
    "time_based": true,
    "all_changes_blocked": true,
    "exception_required": true
  }
}
```

---

## 6. Temporal States

The system operates in one of four temporal states that modify RBAC behavior:

### 6.1 State Definitions

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│    ┌────────┐      ┌─────────────┐      ┌──────────┐   │
│    │ NORMAL │ <--> │ MAINTENANCE │ <--> │ INCIDENT │   │
│    └────────┘      └─────────────┘      └──────────┘   │
│         │                                     │         │
│         └─────────────┬───────────────────────┘         │
│                       v                                  │
│                 ┌──────────┐                            │
│                 │  FREEZE  │                            │
│                 └──────────┘                            │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

| State | Description | Profile Applied |
|-------|-------------|-----------------|
| normal | Standard operations | balanced |
| maintenance | Planned changes in progress | strict |
| incident | Active security incident | lockdown |
| freeze | Code freeze period | lockdown |

### 6.2 State Transitions

| From | To | Trigger | Required Role |
|------|-----|---------|---------------|
| normal | maintenance | Scheduled window or manual | architect |
| normal | incident | Security alert | architect, deployer |
| normal | freeze | Release prep or emergency | architect |
| maintenance | normal | Window expires | automatic |
| incident | normal | Incident resolved | architect + reviewer |
| freeze | normal | Freeze lifted | architect |

### 6.3 State-Specific Rules

#### normal
- Standard separation applies
- All profiles available based on context

#### maintenance
- Strict profile enforced
- Change window restrictions relaxed
- Enhanced audit logging

#### incident
- Lockdown profile enforced
- Only incident-related changes allowed
- All changes require architect approval
- Real-time notifications enabled

#### freeze
- Lockdown profile enforced
- All non-emergency changes blocked
- Exception process required
- Approval chain extended

---

## 7. Implementation

### 7.1 Permission Check Function

```typescript
interface Actor {
  id: string;
  roles: Role[];
}

interface Action {
  type: 'propose' | 'review' | 'approve' | 'execute';
  resource: string;
  proposer_id?: string;
}

interface Context {
  temporal_state: TemporalState;
  profile: Profile;
}

function canPerform(actor: Actor, action: Action, context: Context): boolean {
  // 1. Check temporal state restrictions
  if (!temporalStateAllows(context.temporal_state, action)) {
    return false;
  }

  // 2. Check profile restrictions
  if (!profileAllows(context.profile, action)) {
    return false;
  }

  // 3. Check role permissions
  const hasPermission = actor.roles.some(role =>
    roleHasCapability(role, action.type)
  );
  if (!hasPermission) {
    return false;
  }

  // 4. Check separation of duties
  if (action.type === 'approve' && action.proposer_id === actor.id) {
    return false; // Cannot approve own proposal
  }

  return true;
}
```

### 7.2 Audit Event Schema

Every permission check MUST emit an audit event:

```json
{
  "event": "rbac.permission_check",
  "timestamp": "2026-02-07T12:00:00Z",
  "actor_id": "user-123",
  "actor_roles": ["developer"],
  "action_type": "execute",
  "resource": "deploy-production",
  "context": {
    "temporal_state": "normal",
    "profile": "balanced"
  },
  "result": "allowed|denied",
  "denial_reason": "separation_of_duties|missing_approval|profile_restriction"
}
```

---

## 8. Emergency Procedures

### 8.1 Break Glass Protocol

For situations requiring bypass of normal controls:

1. **Invoke break glass** - Requires 2 people with can_execute
2. **Document justification** - Written reason required
3. **Execute action** - Limited time window (1 hour)
4. **Auto-revert** - System returns to lockdown
5. **Post-incident review** - Mandatory within 24 hours

```bash
# Break glass invocation (requires 2 actors)
./security/scripts/break-glass.sh \
  --reason "Production down, need immediate fix" \
  --duration 1h \
  --actor1 user-123 \
  --actor2 user-456
```

### 8.2 Role Escalation

Temporary role escalation for emergencies:

| From Role | Can Escalate To | Duration | Approval Required |
|-----------|-----------------|----------|-------------------|
| developer | architect | 4 hours | architect |
| reviewer | architect | 4 hours | architect |
| deployer | developer | 4 hours | architect |
| auditor | - | - | Not allowed |

---

## 9. Compliance Mapping

### 9.1 SOC 2 Trust Principles

| Principle | RBAC Control |
|-----------|-------------|
| CC6.1 - Access Control | Role definitions, permission matrix |
| CC6.2 - Registration | Role assignment process |
| CC6.3 - Revocation | Role removal, session termination |
| CC6.6 - Logical Access | Four-way separation |
| CC6.7 - Least Privilege | Minimal role assignment |

### 9.2 NIST 800-53 Controls

| Control | RBAC Mapping |
|---------|-------------|
| AC-2 | Account management via roles |
| AC-3 | Access enforcement via checks |
| AC-5 | Separation of duties |
| AC-6 | Least privilege |
| AU-2 | Audit events |

---

## 10. Review and Maintenance

### 10.1 Quarterly Reviews

- [ ] Review role assignments for least privilege
- [ ] Audit break glass usage
- [ ] Verify separation of duties compliance
- [ ] Update role definitions if needed

### 10.2 Annual Reviews

- [ ] Full access recertification
- [ ] Profile effectiveness assessment
- [ ] Compliance audit preparation
- [ ] Role definition updates

---

**Document Owner**: Security Team
**Review Cycle**: Quarterly
**Next Review**: Q2 2026
