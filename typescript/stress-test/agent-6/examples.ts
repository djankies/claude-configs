import { DataPipeline } from './pipeline';
import { ActivityCategory, TimePeriod } from './types';

export function basicExample() {
  const pipeline = new DataPipeline();

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
      event: 'click',
      element: 'buy-button'
    },
    {
      datetime: '2024-01-15T11:00:00Z',
      uid: 'user123',
      type: 'purchase',
      amount: 99.99
    }
  ];

  const result = pipeline.process(rawLogs);

  console.log(`Processed: ${result.processed}`);
  console.log(`Valid: ${result.valid}`);
  console.log(`Invalid: ${result.invalid}`);
  console.log(`Time series periods: ${result.timeSeries.length}`);

  return result;
}

export function malformedDataExample() {
  const pipeline = new DataPipeline({
    strictMode: false,
    defaultCategory: ActivityCategory.UNKNOWN
  });

  const malformedLogs = [
    { timestamp: '2024-01-15T10:00:00Z', userId: 'user1', action: 'login' },
    { time: 'invalid-date', user: 'user2', event: 'error' },
    { ts: 1705315200000, action: 'click' },
    null,
    'invalid-log-entry',
    { timestamp: '2024-01-15T10:30:00Z' },
    {}
  ];

  const result = pipeline.process(malformedLogs);

  console.log('Errors encountered:');
  result.errors.forEach(error => console.log(`  - ${error}`));

  return result;
}

export function aggregationExample() {
  const pipeline = new DataPipeline({
    aggregationPeriod: TimePeriod.HOURLY
  });

  const logs = Array.from({ length: 100 }, (_, i) => ({
    timestamp: new Date(2024, 0, 15, 10 + Math.floor(i / 20), i % 60, 0).toISOString(),
    userId: `user${i % 10}`,
    action: ['click', 'view', 'purchase', 'error'][i % 4],
    value: i % 4 === 2 ? Math.random() * 100 : undefined
  }));

  const result = pipeline.process(logs);

  console.log('\nTime Series Analysis:');
  result.timeSeries.forEach(ts => {
    console.log(`\nPeriod: ${ts.period}`);
    console.log(`  Activities: ${ts.metrics.totalActivities}`);
    console.log(`  Unique Users: ${ts.metrics.uniqueUsers}`);
    console.log(`  Error Rate: ${(ts.metrics.errorRate * 100).toFixed(2)}%`);
    console.log(`  Average Value: ${ts.metrics.averageValue?.toFixed(2) || 'N/A'}`);
  });

  return result;
}

export function batchProcessingExample() {
  const pipeline = new DataPipeline();

  const batch1 = [
    { timestamp: '2024-01-15T10:00:00Z', userId: 'user1', action: 'login' },
    { timestamp: '2024-01-15T10:30:00Z', userId: 'user2', action: 'view' }
  ];

  const batch2 = [
    { timestamp: '2024-01-15T11:00:00Z', userId: 'user1', action: 'purchase', amount: 50 },
    { timestamp: '2024-01-15T11:15:00Z', userId: 'user3', action: 'error' }
  ];

  const batch3 = [
    { timestamp: '2024-01-16T09:00:00Z', userId: 'user2', action: 'login' },
    { timestamp: '2024-01-16T09:30:00Z', userId: 'user1', action: 'view' }
  ];

  const result = pipeline.batchProcess([batch1, batch2, batch3]);

  console.log('\nBatch Processing Results:');
  console.log(`Total Processed: ${result.processed}`);
  console.log(`Time Periods: ${result.timeSeries.length}`);

  result.timeSeries.forEach(ts => {
    console.log(`\n${ts.period}:`);
    console.log(`  Total: ${ts.metrics.totalActivities}`);
    console.log(`  Users: ${ts.metrics.uniqueUsers}`);
    console.log(`  Categories:`, ts.metrics.byCategory);
  });

  return result;
}

export function customPeriodExample() {
  const pipeline = new DataPipeline();

  const logs = Array.from({ length: 30 }, (_, i) => ({
    timestamp: new Date(2024, 0, 1 + i, 12, 0, 0).toISOString(),
    userId: `user${i % 5}`,
    action: 'activity',
    value: Math.random() * 100
  }));

  console.log('\nWeekly Aggregation:');
  const weeklyResult = pipeline.processWithCustomPeriod(logs, TimePeriod.WEEKLY);
  weeklyResult.timeSeries.forEach(ts => {
    console.log(`${ts.period}: ${ts.metrics.totalActivities} activities`);
  });

  console.log('\nMonthly Aggregation:');
  const monthlyResult = pipeline.processWithCustomPeriod(logs, TimePeriod.MONTHLY);
  monthlyResult.timeSeries.forEach(ts => {
    console.log(`${ts.period}: ${ts.metrics.totalActivities} activities`);
  });

  return { weeklyResult, monthlyResult };
}

export function complexScenario() {
  const pipeline = new DataPipeline({
    strictMode: false,
    defaultCategory: ActivityCategory.UNKNOWN,
    aggregationPeriod: TimePeriod.DAILY
  });

  const complexLogs = [
    {
      timestamp: '2024-01-15T10:00:00Z',
      user: { id: 'user1', name: 'Alice' },
      event: 'page_view',
      metadata: { page: '/home', referrer: 'google' }
    },
    {
      ts: Date.now(),
      userId: 'user2',
      action: 'form_submit',
      formData: { field1: 'value1' },
      value: 1
    },
    {
      created_at: '2024-01-15T11:00:00Z',
      uid: 'USER3',
      type: 'PURCHASE',
      price: '$99.99',
      items: ['item1', 'item2']
    },
    {
      datetime: 'not-a-date',
      user_id: '',
      event_type: ''
    }
  ];

  const result = pipeline.process(complexLogs);

  console.log('\nComplex Scenario Results:');
  console.log(`Processed: ${result.processed}`);
  console.log(`Valid: ${result.valid} (${((result.valid / result.processed) * 100).toFixed(1)}%)`);
  console.log(`Invalid: ${result.invalid}`);

  if (result.errors.length > 0) {
    console.log('\nErrors:');
    result.errors.forEach(err => console.log(`  - ${err}`));
  }

  console.log('\nMetrics by Category:');
  result.timeSeries.forEach(ts => {
    Object.entries(ts.metrics.byCategory).forEach(([category, count]) => {
      if (count > 0) {
        console.log(`  ${category}: ${count}`);
      }
    });
  });

  return result;
}

if (require.main === module) {
  console.log('=== Basic Example ===');
  basicExample();

  console.log('\n=== Malformed Data Example ===');
  malformedDataExample();

  console.log('\n=== Aggregation Example ===');
  aggregationExample();

  console.log('\n=== Batch Processing Example ===');
  batchProcessingExample();

  console.log('\n=== Custom Period Example ===');
  customPeriodExample();

  console.log('\n=== Complex Scenario ===');
  complexScenario();
}
