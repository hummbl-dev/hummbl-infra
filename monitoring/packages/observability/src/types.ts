/**
 * HUMMBL Observability Types
 * Base120: SY18 (Measurement & Telemetry)
 */

export type EventType =
  | 'command.started'
  | 'command.completed'
  | 'command.failed'
  | 'budget.threshold_crossed'
  | 'api.request'
  | 'router.decision'
  | 'alert.triggered'
  | 'integration.dispatch'
  | 'applicationPoint.resolved'
  | 'selector.invoked'
  | 'binding.applied'
  | 'routing.failed';

export type Base120Code =
  | `P${number}`
  | `IN${number}`
  | `CO${number}`
  | `DE${number}`
  | `RE${number}`
  | `SY${number}`;

export type Severity = 'info' | 'warning' | 'critical';

export interface MetricsEvent {
  timestamp: string;
  event_type: EventType;
  source: string;
  correlation_id: string;
  duration_ms?: number;
  exit_code?: number;
  cost_usd?: number;
  transformation?: Base120Code;
  tags?: Record<string, string>;
  metadata?: Record<string, unknown>;
}

export interface HourlyRollup {
  hour: string;
  counters: Record<string, number>;
  gauges: Record<string, number>;
  histograms: Record<string, HistogramData>;
  event_count: number;
}

export interface DailyRollup {
  date: string;
  totals: Record<string, number>;
  peaks: Record<string, number>;
  success_rates: Record<string, number>;
  hourly_breakdown: HourlyRollup[];
}

export interface HistogramData {
  count: number;
  sum: number;
  min: number;
  max: number;
  p50: number;
  p95: number;
  p99: number;
}

export interface AlertRule {
  id: string;
  name: string;
  enabled: boolean;
  condition: AlertCondition;
  severity: Severity;
  actions: AlertAction[];
  fatigue: FatigueConfig;
}

export interface AlertCondition {
  type: 'threshold';
  metric: string;
  operator: '<' | '<=' | '>' | '>=' | '==' | '!=';
  value: number;
  window?: string;
}

export interface AlertAction {
  type: 'console' | 'file' | 'webhook';
  config?: Record<string, unknown>;
}

export interface FatigueConfig {
  cooldown_seconds: number;
  dedup_key?: string;
  max_per_window?: number;
}

export interface TriggeredAlert {
  timestamp: string;
  rule_id: string;
  rule_name: string;
  severity: Severity;
  metric_value: number;
  threshold_value: number;
  dedup_key: string;
}

export interface Sink {
  write(event: MetricsEvent): Promise<void>;
  flush(): Promise<void>;
  close(): Promise<void>;
}
