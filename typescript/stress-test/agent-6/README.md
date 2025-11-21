# Data Transformation Pipeline

A robust TypeScript pipeline for processing user activity logs with unknown structures, transforming them into structured analytics data.

## Features

- **Flexible Parsing**: Handles multiple timestamp formats, user ID variations, and action types
- **Smart Normalization**: Automatically categorizes activities and extracts values
- **Time-based Aggregation**: Supports hourly, daily, weekly, and monthly aggregations
- **Error Handling**: Gracefully processes malformed data with detailed error reporting
- **Batch Processing**: Efficiently processes multiple data batches
- **Type Safety**: Full TypeScript support with comprehensive type definitions

## Installation

```bash
npm install
```

## Quick Start

```typescript
import { DataPipeline, TimePeriod } from './index';

const pipeline = new DataPipeline({
  aggregationPeriod: TimePeriod.DAILY
});

const rawLogs = [
  {
    timestamp: '2024-01-15T10:30:00Z',
    userId: 'user123',
    action: 'page_view',
    page: '/home'
  },
  {
    ts: 1705315200000,
    user_id: 'user456',
    event: 'purchase',
    amount: 99.99
  }
];

const result = pipeline.process(rawLogs);

console.log(`Processed: ${result.processed}`);
console.log(`Valid: ${result.valid}`);
console.log(`Time series periods: ${result.timeSeries.length}`);
```

## Architecture

### Components

1. **LogParser** (`parser.ts`)
   - Parses raw log entries with flexible field detection
   - Supports multiple field name variations (timestamp/ts/time, userId/user_id/uid, etc.)
   - Validates and extracts metadata

2. **DataNormalizer** (`normalizer.ts`)
   - Transforms parsed data into normalized structures
   - Categorizes activities (navigation, interaction, transaction, error)
   - Extracts numeric values from various formats
   - Sanitizes metadata

3. **DataAggregator** (`aggregator.ts`)
   - Groups activities by time periods
   - Calculates comprehensive metrics
   - Supports multiple aggregation periods

4. **DataPipeline** (`pipeline.ts`)
   - Orchestrates the entire transformation process
   - Supports batch processing
   - Configurable behavior

### Data Flow

```
Raw Logs → Parser → Normalized Activities → Aggregator → Time Series Data
```

## Configuration

```typescript
interface PipelineConfig {
  strictMode: boolean;           // Reject invalid entries
  defaultCategory: ActivityCategory;  // Default for uncategorized actions
  timeZone: string;              // Timezone for aggregation
  aggregationPeriod: TimePeriod; // Time period granularity
}
```

## Supported Input Formats

The parser automatically detects and handles:

### Timestamp Fields
- `timestamp`, `time`, `ts`, `date`, `datetime`, `created_at`, `createdAt`
- Supports ISO strings, Unix timestamps, Date objects

### User ID Fields
- `userId`, `user_id`, `uid`, `user`, `username`, `id`
- Handles strings, numbers, nested objects

### Action Fields
- `action`, `event`, `type`, `activity`, `eventType`, `event_type`

### Value Fields
- `value`, `amount`, `price`, `total`, `count`, `quantity`
- Automatically parses currency strings

## Activity Categories

- **NAVIGATION**: Page views, clicks, scrolling
- **INTERACTION**: Form submissions, searches, inputs
- **TRANSACTION**: Purchases, payments, checkouts
- **ERROR**: Errors, exceptions, failures
- **UNKNOWN**: Uncategorized activities

## Aggregation Periods

- **HOURLY**: Aggregate by hour
- **DAILY**: Aggregate by day
- **WEEKLY**: Aggregate by ISO week
- **MONTHLY**: Aggregate by month

## Examples

### Basic Processing

```typescript
const pipeline = new DataPipeline();
const result = pipeline.process(rawLogs);
```

### Strict Mode

```typescript
const pipeline = new DataPipeline({
  strictMode: true  // Only process valid entries
});
```

### Custom Time Period

```typescript
const result = pipeline.processWithCustomPeriod(rawLogs, TimePeriod.WEEKLY);
```

### Batch Processing

```typescript
const batches = [batch1, batch2, batch3];
const result = pipeline.batchProcess(batches);
```

### Malformed Data Handling

```typescript
const pipeline = new DataPipeline({ strictMode: false });

const malformedLogs = [
  { timestamp: '2024-01-15T10:00:00Z', userId: 'user1', action: 'login' },
  { time: 'invalid-date', user: 'user2', event: 'error' },
  null,
  'not-an-object',
  {}
];

const result = pipeline.process(malformedLogs);
console.log(result.errors);  // Detailed error messages
```

## Output Format

```typescript
interface PipelineResult {
  processed: number;           // Total entries processed
  valid: number;               // Valid entries
  invalid: number;             // Invalid entries
  timeSeries: TimeSeriesData[]; // Aggregated time series
  errors: string[];            // Error messages
}

interface TimeSeriesData {
  period: string;              // Period identifier
  startTime: Date;             // Period start
  endTime: Date;               // Period end
  activities: NormalizedActivity[]; // All activities in period
  metrics: AggregatedMetrics;  // Calculated metrics
}

interface AggregatedMetrics {
  totalActivities: number;
  uniqueUsers: number;
  byCategory: Record<ActivityCategory, number>;
  byAction: Record<string, number>;
  errorRate: number;
  averageValue?: number;
}
```

## Performance Considerations

- Designed for fast quarterly report generation
- Handles large datasets efficiently
- Batch processing for memory optimization
- Minimal dependencies

## Error Handling

The pipeline gracefully handles:
- Missing or null entries
- Invalid timestamps
- Missing required fields
- Type mismatches
- Malformed data structures

All errors are logged and returned in the result object without stopping processing.

## Running Examples

```bash
npx ts-node examples.ts
```

This runs comprehensive examples demonstrating all pipeline features.

## Files

- `types.ts`: Type definitions and interfaces
- `parser.ts`: Log parsing logic
- `normalizer.ts`: Data normalization and categorization
- `aggregator.ts`: Time-based aggregation
- `pipeline.ts`: Main pipeline orchestration
- `index.ts`: Public API exports
- `examples.ts`: Usage examples
- `README.md`: Documentation

## License

MIT
