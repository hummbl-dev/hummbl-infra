/**
 * HUMMBL Metrics Collector
 * Base120: SY18 (Measurement & Telemetry)
 */

import { appendFile, mkdir } from 'node:fs/promises';
import { dirname } from 'node:path';
import type { MetricsEvent, EventType, Sink, Base120Code } from './types.js';

export class FileSink implements Sink {
  private buffer: string[] = [];
  private readonly maxBufferSize: number;

  constructor(
    private readonly path: string,
    maxBufferSize = 100
  ) {
    this.maxBufferSize = maxBufferSize;
  }

  async write(event: MetricsEvent): Promise<void> {
    this.buffer.push(JSON.stringify(event));
    if (this.buffer.length >= this.maxBufferSize) {
      await this.flush();
    }
  }

  async flush(): Promise<void> {
    if (this.buffer.length === 0) return;

    await mkdir(dirname(this.path), { recursive: true });
    const data = this.buffer.join('\n') + '\n';
    this.buffer = [];
    await appendFile(this.path, data, 'utf-8');
  }

  async close(): Promise<void> {
    await this.flush();
  }
}

export class ConsoleSink implements Sink {
  async write(event: MetricsEvent): Promise<void> {
    console.log(JSON.stringify(event));
  }

  async flush(): Promise<void> {}
  async close(): Promise<void> {}
}

export class MemorySink implements Sink {
  public events: MetricsEvent[] = [];

  async write(event: MetricsEvent): Promise<void> {
    this.events.push(event);
  }

  async flush(): Promise<void> {}
  async close(): Promise<void> {}

  clear(): void {
    this.events = [];
  }
}

export class MetricsCollector {
  private readonly sinks: Sink[];
  private readonly source: string;

  constructor(source: string, sinks: Sink[]) {
    this.source = source;
    this.sinks = sinks;
  }

  async emit(
    eventType: EventType,
    data: Partial<Omit<MetricsEvent, 'timestamp' | 'event_type' | 'source'>>
  ): Promise<void> {
    const event: MetricsEvent = {
      timestamp: new Date().toISOString(),
      event_type: eventType,
      source: this.source,
      correlation_id: data.correlation_id ?? crypto.randomUUID(),
      ...data,
    };

    await Promise.all(this.sinks.map((sink) => sink.write(event)));
  }

  async commandStarted(
    command: string,
    args: string[],
    options?: { correlation_id?: string; transformation?: Base120Code }
  ): Promise<void> {
    await this.emit('command.started', {
      correlation_id: options?.correlation_id,
      transformation: options?.transformation,
      metadata: { command, args },
    });
  }

  async commandCompleted(
    command: string,
    durationMs: number,
    exitCode: number,
    options?: { correlation_id?: string; transformation?: Base120Code }
  ): Promise<void> {
    await this.emit('command.completed', {
      correlation_id: options?.correlation_id,
      transformation: options?.transformation,
      duration_ms: durationMs,
      exit_code: exitCode,
      metadata: { command },
    });
  }

  async commandFailed(
    command: string,
    exitCode: number,
    errorMessage: string,
    options?: { correlation_id?: string; durationMs?: number }
  ): Promise<void> {
    await this.emit('command.failed', {
      correlation_id: options?.correlation_id,
      duration_ms: options?.durationMs,
      exit_code: exitCode,
      metadata: { command, error_message: errorMessage },
    });
  }

  async apiRequest(
    endpoint: string,
    statusCode: number,
    durationMs: number,
    costUsd?: number
  ): Promise<void> {
    await this.emit('api.request', {
      duration_ms: durationMs,
      cost_usd: costUsd,
      metadata: { endpoint, status_code: statusCode },
    });
  }

  async budgetThresholdCrossed(
    thresholdName: string,
    previousCost: number,
    currentCost: number
  ): Promise<void> {
    await this.emit('budget.threshold_crossed', {
      cost_usd: currentCost,
      metadata: { threshold_name: thresholdName, previous_cost: previousCost },
    });
  }

  async flush(): Promise<void> {
    await Promise.all(this.sinks.map((sink) => sink.flush()));
  }

  async close(): Promise<void> {
    await Promise.all(this.sinks.map((sink) => sink.close()));
  }
}

export function createFileCollector(
  path: string,
  source: string
): MetricsCollector {
  return new MetricsCollector(source, [new FileSink(path)]);
}

export function createConsoleCollector(source: string): MetricsCollector {
  return new MetricsCollector(source, [new ConsoleSink()]);
}
