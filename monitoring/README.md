# Monitoring/Observability

Metrics collection, aggregation, alerting, and dashboards.

## Structure

```
monitoring/
├── configs/
│   ├── alert-rules.yaml
│   └── thresholds.json
├── scripts/
│   ├── aggregate-hourly.sh
│   ├── aggregate-daily.sh
│   └── metrics-cleanup.sh
├── packages/
│   └── observability/
│       ├── src/
│       │   ├── collector.ts
│       │   ├── aggregator.ts
│       │   ├── alert-evaluator.ts
│       │   └── sinks/
│       └── package.json
├── schemas/
│   └── metrics-event.schema.json
└── docs/
    └── observability-guide.md
```

## Deliverables

- [ ] Metrics event schema
- [ ] Collector module
- [ ] Hourly/daily aggregator
- [ ] Alert rule engine
- [ ] Terminal dashboard
- [ ] Static HTML reports

## Core Events

From telemetry research:
1. `integration.dispatch`
2. `applicationPoint.resolved`
3. `selector.invoked`
4. `binding.applied`
5. `routing.failed`

## Constraint

**Offline-First**: All metrics must use file-based storage (JSONL/JSON).

## Patterns

Based on research from:
- `/workspace/active/hummbl-agent/packages/router/src/base120/telemetry.ts`
- `/workspace/active/hummbl-agent/packages/governance/src/audit.ts`
