/**
 * HUMMBL Observability Package
 * Base120: SY18 (Measurement & Telemetry)
 *
 * @example
 * ```typescript
 * import { createFileCollector } from '@hummbl/observability';
 *
 * const collector = createFileCollector('_state/metrics/events.jsonl', 'my-service');
 * await collector.commandStarted('git', ['status']);
 * await collector.commandCompleted('git status', 150, 0);
 * await collector.close();
 * ```
 */

// Types
export type {
  EventType,
  Base120Code,
  Severity,
  MetricsEvent,
  HourlyRollup,
  DailyRollup,
  HistogramData,
  AlertRule,
  AlertCondition,
  AlertAction,
  FatigueConfig,
  TriggeredAlert,
  Sink,
} from './types.js';

// Collector
export {
  MetricsCollector,
  FileSink,
  ConsoleSink,
  MemorySink,
  createFileCollector,
  createConsoleCollector,
} from './collector.js';
