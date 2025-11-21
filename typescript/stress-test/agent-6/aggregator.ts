import {
  NormalizedActivity,
  TimeSeriesData,
  AggregatedMetrics,
  ActivityCategory,
  TimePeriod
} from './types';

export class DataAggregator {
  private timeZone: string;

  constructor(timeZone: string = 'UTC') {
    this.timeZone = timeZone;
  }

  aggregate(activities: NormalizedActivity[], period: TimePeriod): TimeSeriesData[] {
    if (activities.length === 0) {
      return [];
    }

    const grouped = this.groupByPeriod(activities, period);
    const timeSeries: TimeSeriesData[] = [];

    for (const [periodKey, periodActivities] of grouped.entries()) {
      const [startTime, endTime] = this.getPeriodBounds(periodKey, period);
      const metrics = this.calculateMetrics(periodActivities);

      timeSeries.push({
        period: periodKey,
        startTime,
        endTime,
        activities: periodActivities,
        metrics
      });
    }

    return timeSeries.sort((a, b) => a.startTime.getTime() - b.startTime.getTime());
  }

  private groupByPeriod(
    activities: NormalizedActivity[],
    period: TimePeriod
  ): Map<string, NormalizedActivity[]> {
    const grouped = new Map<string, NormalizedActivity[]>();

    for (const activity of activities) {
      const key = this.getPeriodKey(activity.timestamp, period);

      if (!grouped.has(key)) {
        grouped.set(key, []);
      }

      grouped.get(key)!.push(activity);
    }

    return grouped;
  }

  private getPeriodKey(date: Date, period: TimePeriod): string {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    const hour = String(date.getHours()).padStart(2, '0');

    switch (period) {
      case TimePeriod.HOURLY:
        return `${year}-${month}-${day}T${hour}:00:00`;

      case TimePeriod.DAILY:
        return `${year}-${month}-${day}`;

      case TimePeriod.WEEKLY:
        const weekNumber = this.getWeekNumber(date);
        return `${year}-W${String(weekNumber).padStart(2, '0')}`;

      case TimePeriod.MONTHLY:
        return `${year}-${month}`;

      default:
        return `${year}-${month}-${day}`;
    }
  }

  private getPeriodBounds(periodKey: string, period: TimePeriod): [Date, Date] {
    let startTime: Date;
    let endTime: Date;

    switch (period) {
      case TimePeriod.HOURLY:
        startTime = new Date(periodKey);
        endTime = new Date(startTime.getTime() + 60 * 60 * 1000);
        break;

      case TimePeriod.DAILY:
        startTime = new Date(periodKey + 'T00:00:00');
        endTime = new Date(startTime.getTime() + 24 * 60 * 60 * 1000);
        break;

      case TimePeriod.WEEKLY:
        const [year, week] = periodKey.split('-W').map(Number);
        startTime = this.getDateFromWeek(year, week);
        endTime = new Date(startTime.getTime() + 7 * 24 * 60 * 60 * 1000);
        break;

      case TimePeriod.MONTHLY:
        startTime = new Date(periodKey + '-01T00:00:00');
        const nextMonth = new Date(startTime);
        nextMonth.setMonth(nextMonth.getMonth() + 1);
        endTime = nextMonth;
        break;

      default:
        startTime = new Date(periodKey);
        endTime = new Date(startTime.getTime() + 24 * 60 * 60 * 1000);
    }

    return [startTime, endTime];
  }

  private getWeekNumber(date: Date): number {
    const firstDayOfYear = new Date(date.getFullYear(), 0, 1);
    const pastDaysOfYear = (date.getTime() - firstDayOfYear.getTime()) / 86400000;
    return Math.ceil((pastDaysOfYear + firstDayOfYear.getDay() + 1) / 7);
  }

  private getDateFromWeek(year: number, week: number): Date {
    const firstDayOfYear = new Date(year, 0, 1);
    const daysOffset = (week - 1) * 7 - firstDayOfYear.getDay() + 1;
    return new Date(year, 0, 1 + daysOffset);
  }

  private calculateMetrics(activities: NormalizedActivity[]): AggregatedMetrics {
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

  aggregateAll(timeSeries: TimeSeriesData[]): AggregatedMetrics {
    const allActivities = timeSeries.flatMap(ts => ts.activities);
    return this.calculateMetrics(allActivities);
  }
}
