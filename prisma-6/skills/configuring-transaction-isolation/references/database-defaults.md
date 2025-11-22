# Database-Specific Defaults

## PostgreSQL

Default: `ReadCommitted`

Supported levels:

- `Serializable` (strictest)
- `RepeatableRead`
- `ReadCommitted` (default)

Notes:

- PostgreSQL uses true Serializable isolation (not snapshot isolation)
- May throw serialization errors under high concurrency
- Excellent MVCC implementation reduces conflicts

## MySQL

Default: `RepeatableRead`

Supported levels:

- `Serializable`
- `RepeatableRead` (default)
- `ReadCommitted`
- `ReadUncommitted` (not recommended)

Notes:

- InnoDB engine required for transaction support
- Uses gap locking in RepeatableRead mode
- Serializable adds locking to SELECT statements

## SQLite

Default: `Serializable`

Supported levels:

- `Serializable` (only level - database-wide lock)

Notes:

- Only one writer at a time
- No true isolation level configuration
- Best for single-user or low-concurrency applications

## MongoDB

Default: `Snapshot` (similar to RepeatableRead)

Supported levels:

- `Snapshot` (equivalent to RepeatableRead)
- `Majority` read concern

Notes:

- Different isolation model than SQL databases
- Uses write-ahead log for consistency
- Replica set required for transactions
