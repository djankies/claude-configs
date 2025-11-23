# File Locking Strategy

The hook system uses a dual-strategy approach for file locking to support both Linux and macOS platforms.

## Locking Mechanisms

### 1. flock (Linux/Primary)
- Uses the `flock` utility when available
- Efficient kernel-level file locking
- Native on Linux systems with util-linux package

### 2. mkdir (macOS/Fallback)
- Uses atomic `mkdir` operations when flock is unavailable
- Fully reliable and atomic on all POSIX systems
- No installation required

## Platform Behavior

### macOS
- **Default**: Uses mkdir-based locking (flock not available)
- **Status**: ✅ Fully functional - no action required
- **Performance**: Negligible overhead for typical use cases

The mkdir approach is:
- ✅ Fully atomic (mkdir is a POSIX atomic operation)
- ✅ Reliable for concurrent access
- ✅ No functional differences from flock
- ✅ No installation or configuration required

### Linux
- **Default**: Uses flock (installed with util-linux)
- **Fallback**: Automatically uses mkdir if flock unavailable

## Performance Characteristics

For typical hook execution patterns (5-10 locks per file write):
- flock: ~0.1ms per lock operation
- mkdir: ~0.2ms per lock operation
- Difference: Negligible for hook execution times (typically 5-50ms total)

## Optional flock Installation (macOS)

Installing flock on macOS provides marginal performance gains but is **not required**:

```bash
# Via Homebrew
brew install util-linux

# Note: May require additional PATH configuration
# The mkdir fallback works perfectly without this
```

## Implementation Details

The locking implementation in `session-management.sh`:

1. Checks for flock availability
2. Falls back to mkdir if not available
3. Both methods support configurable timeouts (default: 10s)
4. Both methods handle lock release and cleanup

### Code Flow

```bash
acquire_lock() {
    if flock available:
        use flock with file descriptor
    else:
        use mkdir with lock directory
    return success/failure
}
```

## Troubleshooting

### "Lock acquisition failed" errors

These indicate genuine lock contention, not locking mechanism issues:
- Another hook is holding the lock
- Increase timeout if operations take >10s
- Check for hung hook processes

### Debugging

Enable debug logging to see locking details:
```bash
export CLAUDE_DEBUG_LEVEL=DEBUG
```

Debug logs will show:
- Which locking mechanism is active
- Lock acquisition attempts
- Lock timeouts and failures
