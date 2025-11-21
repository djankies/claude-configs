import { RawLogEntry, ParsedLogEntry } from './types';

export class LogParser {
  private errors: string[] = [];

  parse(rawData: unknown): ParsedLogEntry[] {
    this.errors = [];

    if (!rawData) {
      return [];
    }

    if (Array.isArray(rawData)) {
      return rawData.map((entry, index) => this.parseEntry(entry, index));
    }

    return [this.parseEntry(rawData, 0)];
  }

  private parseEntry(entry: unknown, index: number): ParsedLogEntry {
    const errors: string[] = [];
    let valid = true;

    if (typeof entry !== 'object' || entry === null) {
      errors.push(`Entry ${index}: Not an object`);
      return this.createInvalidEntry(errors);
    }

    const raw = entry as RawLogEntry;

    const timestamp = this.extractTimestamp(raw, errors);
    if (!timestamp) {
      valid = false;
    }

    const userId = this.extractUserId(raw, errors);
    if (!userId) {
      valid = false;
    }

    const action = this.extractAction(raw, errors);
    if (!action) {
      valid = false;
    }

    const metadata = this.extractMetadata(raw);

    return {
      timestamp: timestamp || new Date(),
      userId: userId || 'unknown',
      action: action || 'unknown',
      metadata,
      valid,
      errors: errors.length > 0 ? errors : undefined
    };
  }

  private extractTimestamp(raw: RawLogEntry, errors: string[]): Date | null {
    const possibleKeys = ['timestamp', 'time', 'ts', 'date', 'datetime', 'created_at', 'createdAt'];

    for (const key of possibleKeys) {
      if (key in raw) {
        const value = raw[key];

        if (value instanceof Date) {
          return value;
        }

        if (typeof value === 'string' || typeof value === 'number') {
          const parsed = new Date(value);
          if (!isNaN(parsed.getTime())) {
            return parsed;
          }
        }
      }
    }

    errors.push('Missing or invalid timestamp');
    return null;
  }

  private extractUserId(raw: RawLogEntry, errors: string[]): string | null {
    const possibleKeys = ['userId', 'user_id', 'uid', 'user', 'username', 'id'];

    for (const key of possibleKeys) {
      if (key in raw) {
        const value = raw[key];

        if (typeof value === 'string' && value.trim()) {
          return value.trim();
        }

        if (typeof value === 'number') {
          return String(value);
        }

        if (typeof value === 'object' && value !== null) {
          const obj = value as Record<string, unknown>;
          if ('id' in obj && typeof obj.id === 'string') {
            return obj.id;
          }
        }
      }
    }

    errors.push('Missing or invalid userId');
    return null;
  }

  private extractAction(raw: RawLogEntry, errors: string[]): string | null {
    const possibleKeys = ['action', 'event', 'type', 'activity', 'eventType', 'event_type'];

    for (const key of possibleKeys) {
      if (key in raw) {
        const value = raw[key];

        if (typeof value === 'string' && value.trim()) {
          return value.trim();
        }
      }
    }

    errors.push('Missing or invalid action');
    return null;
  }

  private extractMetadata(raw: RawLogEntry): Record<string, unknown> {
    const metadata: Record<string, unknown> = {};
    const excludeKeys = new Set([
      'timestamp', 'time', 'ts', 'date', 'datetime', 'created_at', 'createdAt',
      'userId', 'user_id', 'uid', 'user', 'username',
      'action', 'event', 'type', 'activity', 'eventType', 'event_type'
    ]);

    for (const [key, value] of Object.entries(raw)) {
      if (!excludeKeys.has(key)) {
        metadata[key] = value;
      }
    }

    return metadata;
  }

  private createInvalidEntry(errors: string[]): ParsedLogEntry {
    return {
      timestamp: new Date(),
      userId: 'unknown',
      action: 'unknown',
      metadata: {},
      valid: false,
      errors
    };
  }

  getErrors(): string[] {
    return this.errors;
  }
}
