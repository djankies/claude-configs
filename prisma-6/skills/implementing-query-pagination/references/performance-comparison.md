# Performance Comparison

## Benchmark: 500k Posts

**Cursor Pagination (id index):**
- Page 1: 8ms
- Page 100: 9ms
- Page 1000: 10ms
- Page 10000: 11ms
- **Stable performance**

**Offset Pagination (createdAt index):**
- Page 1: 7ms
- Page 100: 95ms
- Page 1000: 890ms
- Page 10000: 8,900ms
- **Linear degradation**

## Memory Usage

Both approaches:
- Load only pageSize records into memory
- Similar memory footprint for same page size
- Database performs filtering/sorting

## Database Load

**Cursor:**
- Index scan from cursor position
- Reads pageSize + 1 rows (for hasMore check)

**Offset:**
- Index scan from beginning
- Skips offset rows (database work, not returned)
- Reads pageSize rows

## Optimization Guidelines

1. **Always add indexes** on ordering fields
2. **Test with realistic data volumes** before production
3. **Monitor query performance** in production
4. **Cache total counts** for offset pagination when possible
5. **Use cursor by default** unless specific requirements demand offset
