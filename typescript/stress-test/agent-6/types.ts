export interface RawLogEntry {
  [key: string]: unknown;
}

export interface ParsedLogEntry {
  timestamp: Date;
  userId: string;
  action: string;
  metadata: Record<string, unknown>;
  valid: boolean;
  errors?: string[];
}

export interface NormalizedActivity {
  timestamp: Date;
  userId: string;
  action: string;
  category: ActivityCategory;
  value?: number;
  metadata: Record<string, unknown>;
}

export enum ActivityCategory {
  NAVIGATION = 'navigation',
  INTERACTION = 'interaction',
  TRANSACTION = 'transaction',
  ERROR = 'error',
  UNKNOWN = 'unknown'
}

export interface TimeSeriesData {
  period: string;
  startTime: Date;
  endTime: Date;
  activities: NormalizedActivity[];
  metrics: AggregatedMetrics;
}

export interface AggregatedMetrics {
  totalActivities: number;
  uniqueUsers: number;
  byCategory: Record<ActivityCategory, number>;
  byAction: Record<string, number>;
  errorRate: number;
  averageValue?: number;
}

export enum TimePeriod {
  HOURLY = 'hourly',
  DAILY = 'daily',
  WEEKLY = 'weekly',
  MONTHLY = 'monthly'
}

export interface PipelineConfig {
  strictMode: boolean;
  defaultCategory: ActivityCategory;
  timeZone: string;
  aggregationPeriod: TimePeriod;
}

export interface PipelineResult {
  processed: number;
  valid: number;
  invalid: number;
  timeSeries: TimeSeriesData[];
  errors: string[];
}
