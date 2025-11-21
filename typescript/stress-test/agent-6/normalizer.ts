import { ParsedLogEntry, NormalizedActivity, ActivityCategory, PipelineConfig } from './types';

export class DataNormalizer {
  private config: PipelineConfig;
  private actionCategoryMap: Map<string, ActivityCategory>;

  constructor(config: PipelineConfig) {
    this.config = config;
    this.actionCategoryMap = this.buildActionCategoryMap();
  }

  normalize(entries: ParsedLogEntry[]): NormalizedActivity[] {
    return entries
      .filter(entry => !this.config.strictMode || entry.valid)
      .map(entry => this.normalizeEntry(entry));
  }

  private normalizeEntry(entry: ParsedLogEntry): NormalizedActivity {
    const category = this.categorizeAction(entry.action);
    const value = this.extractValue(entry.metadata);

    return {
      timestamp: entry.timestamp,
      userId: this.normalizeUserId(entry.userId),
      action: this.normalizeAction(entry.action),
      category,
      value,
      metadata: this.sanitizeMetadata(entry.metadata)
    };
  }

  private categorizeAction(action: string): ActivityCategory {
    const normalized = action.toLowerCase();

    if (this.actionCategoryMap.has(normalized)) {
      return this.actionCategoryMap.get(normalized)!;
    }

    if (normalized.includes('click') || normalized.includes('view') || normalized.includes('navigate')) {
      return ActivityCategory.NAVIGATION;
    }

    if (normalized.includes('submit') || normalized.includes('create') || normalized.includes('update')) {
      return ActivityCategory.INTERACTION;
    }

    if (normalized.includes('purchase') || normalized.includes('payment') || normalized.includes('checkout')) {
      return ActivityCategory.TRANSACTION;
    }

    if (normalized.includes('error') || normalized.includes('fail') || normalized.includes('exception')) {
      return ActivityCategory.ERROR;
    }

    return this.config.defaultCategory;
  }

  private buildActionCategoryMap(): Map<string, ActivityCategory> {
    const map = new Map<string, ActivityCategory>();

    map.set('page_view', ActivityCategory.NAVIGATION);
    map.set('pageview', ActivityCategory.NAVIGATION);
    map.set('click', ActivityCategory.NAVIGATION);
    map.set('navigation', ActivityCategory.NAVIGATION);
    map.set('scroll', ActivityCategory.NAVIGATION);

    map.set('form_submit', ActivityCategory.INTERACTION);
    map.set('button_click', ActivityCategory.INTERACTION);
    map.set('input', ActivityCategory.INTERACTION);
    map.set('select', ActivityCategory.INTERACTION);
    map.set('search', ActivityCategory.INTERACTION);

    map.set('purchase', ActivityCategory.TRANSACTION);
    map.set('payment', ActivityCategory.TRANSACTION);
    map.set('checkout', ActivityCategory.TRANSACTION);
    map.set('order', ActivityCategory.TRANSACTION);
    map.set('subscription', ActivityCategory.TRANSACTION);

    map.set('error', ActivityCategory.ERROR);
    map.set('exception', ActivityCategory.ERROR);
    map.set('crash', ActivityCategory.ERROR);
    map.set('timeout', ActivityCategory.ERROR);
    map.set('failure', ActivityCategory.ERROR);

    return map;
  }

  private normalizeUserId(userId: string): string {
    return userId.toLowerCase().trim();
  }

  private normalizeAction(action: string): string {
    return action.toLowerCase().replace(/[^a-z0-9_]/g, '_');
  }

  private extractValue(metadata: Record<string, unknown>): number | undefined {
    const possibleKeys = ['value', 'amount', 'price', 'total', 'count', 'quantity'];

    for (const key of possibleKeys) {
      if (key in metadata) {
        const value = metadata[key];

        if (typeof value === 'number' && !isNaN(value)) {
          return value;
        }

        if (typeof value === 'string') {
          const parsed = parseFloat(value.replace(/[^0-9.-]/g, ''));
          if (!isNaN(parsed)) {
            return parsed;
          }
        }
      }
    }

    return undefined;
  }

  private sanitizeMetadata(metadata: Record<string, unknown>): Record<string, unknown> {
    const sanitized: Record<string, unknown> = {};

    for (const [key, value] of Object.entries(metadata)) {
      if (this.isSafeValue(value)) {
        sanitized[key] = value;
      } else if (typeof value === 'object' && value !== null) {
        sanitized[key] = '[Object]';
      } else {
        sanitized[key] = String(value);
      }
    }

    return sanitized;
  }

  private isSafeValue(value: unknown): boolean {
    return (
      typeof value === 'string' ||
      typeof value === 'number' ||
      typeof value === 'boolean' ||
      value === null
    );
  }
}
