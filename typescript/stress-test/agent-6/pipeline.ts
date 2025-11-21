import { LogParser } from './parser';
import { DataNormalizer } from './normalizer';
import { DataAggregator } from './aggregator';
import {
  PipelineConfig,
  PipelineResult,
  ActivityCategory,
  TimePeriod,
  TimeSeriesData
} from './types';

export class DataPipeline {
  private parser: LogParser;
  private normalizer: DataNormalizer;
  private aggregator: DataAggregator;
  private config: PipelineConfig;

  constructor(config?: Partial<PipelineConfig>) {
    this.config = {
      strictMode: false,
      defaultCategory: ActivityCategory.UNKNOWN,
      timeZone: 'UTC',
      aggregationPeriod: TimePeriod.DAILY,
      ...config
    };

    this.parser = new LogParser();
    this.normalizer = new DataNormalizer(this.config);
    this.aggregator = new DataAggregator(this.config.timeZone);
  }

  process(rawData: unknown): PipelineResult {
    const errors: string[] = [];

    try {
      const parsed = this.parser.parse(rawData);
      const parserErrors = this.parser.getErrors();
      errors.push(...parserErrors);

      const valid = parsed.filter(entry => entry.valid).length;
      const invalid = parsed.length - valid;

      const normalized = this.normalizer.normalize(parsed);

      const timeSeries = this.aggregator.aggregate(
        normalized,
        this.config.aggregationPeriod
      );

      return {
        processed: parsed.length,
        valid,
        invalid,
        timeSeries,
        errors
      };
    } catch (error) {
      errors.push(`Pipeline error: ${error instanceof Error ? error.message : String(error)}`);

      return {
        processed: 0,
        valid: 0,
        invalid: 0,
        timeSeries: [],
        errors
      };
    }
  }

  processWithCustomPeriod(rawData: unknown, period: TimePeriod): PipelineResult {
    const originalPeriod = this.config.aggregationPeriod;
    this.config.aggregationPeriod = period;

    const result = this.process(rawData);

    this.config.aggregationPeriod = originalPeriod;
    return result;
  }

  batchProcess(rawDataBatches: unknown[]): PipelineResult {
    const errors: string[] = [];
    let totalProcessed = 0;
    let totalValid = 0;
    let totalInvalid = 0;
    const allTimeSeries: TimeSeriesData[] = [];

    for (let i = 0; i < rawDataBatches.length; i++) {
      const result = this.process(rawDataBatches[i]);

      totalProcessed += result.processed;
      totalValid += result.valid;
      totalInvalid += result.invalid;
      allTimeSeries.push(...result.timeSeries);

      if (result.errors.length > 0) {
        errors.push(`Batch ${i}: ${result.errors.join(', ')}`);
      }
    }

    const mergedTimeSeries = this.mergeTimeSeries(allTimeSeries);

    return {
      processed: totalProcessed,
      valid: totalValid,
      invalid: totalInvalid,
      timeSeries: mergedTimeSeries,
      errors
    };
  }

  private mergeTimeSeries(timeSeries: TimeSeriesData[]): TimeSeriesData[] {
    const periodMap = new Map<string, TimeSeriesData>();

    for (const ts of timeSeries) {
      if (periodMap.has(ts.period)) {
        const existing = periodMap.get(ts.period)!;
        existing.activities.push(...ts.activities);

        const allActivities = existing.activities;
        existing.metrics = this.recalculateMetrics(allActivities);
      } else {
        periodMap.set(ts.period, { ...ts });
      }
    }

    return Array.from(periodMap.values()).sort(
      (a, b) => a.startTime.getTime() - b.startTime.getTime()
    );
  }

  private recalculateMetrics(activities: import('./types').NormalizedActivity[]): import('./types').AggregatedMetrics {
    const totalActivities = activities.length;
    const uniqueUsers = new Set(activities.map(a => a.userId)).size;

    const byCategory: Record<ActivityCategory, number> = {
      [ActivityCategory.NAVIGATION]: 0,
      [ActivityCategory.INTERACTION]: 0,
      [ActivityCategory.TRANSACTION]: 0,
      [ActivityCategory.ERROR]: 0,
      [ActivityCategory.UNKNOWN]: 0
    };

    const byAction: Record<string, number> = {};
    let errorCount = 0;
    let totalValue = 0;
    let valueCount = 0;

    for (const activity of activities) {
      byCategory[activity.category]++;
      byAction[activity.action] = (byAction[activity.action] || 0) + 1;

      if (activity.category === ActivityCategory.ERROR) {
        errorCount++;
      }

      if (activity.value !== undefined) {
        totalValue += activity.value;
        valueCount++;
      }
    }

    const errorRate = totalActivities > 0 ? errorCount / totalActivities : 0;
    const averageValue = valueCount > 0 ? totalValue / valueCount : undefined;

    return {
      totalActivities,
      uniqueUsers,
      byCategory,
      byAction,
      errorRate,
      averageValue
    };
  }

  getConfig(): PipelineConfig {
    return { ...this.config };
  }

  updateConfig(config: Partial<PipelineConfig>): void {
    this.config = { ...this.config, ...config };
    this.normalizer = new DataNormalizer(this.config);
    this.aggregator = new DataAggregator(this.config.timeZone);
  }
}
