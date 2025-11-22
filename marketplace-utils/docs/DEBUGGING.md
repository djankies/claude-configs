# Debugging Guide

Comprehensive guide for debugging Claude Code session management, logging, and error handling.

## Table of Contents

- [Environment Variables](#environment-variables)
- [Real-Time Log Monitoring](#real-time-log-monitoring)
- [Error Investigation](#error-investigation)
- [Session Inspection](#session-inspection)
- [Common Issues](#common-issues)
- [Debugging Workflow](#debugging-workflow)

## Environment Variables

### Official Claude Code Variables

#### `CLAUDE_DEBUG_LEVEL`

Controls the minimum log level to display.

**Values:** `DEBUG`, `INFO`, `WARN`, `ERROR`, `FATAL`

**Default:** `WARN`

```bash
export CLAUDE_DEBUG_LEVEL=DEBUG
export CLAUDE_DEBUG_LEVEL=INFO
export CLAUDE_DEBUG_LEVEL=WARN
export CLAUDE_DEBUG_LEVEL=ERROR
```

**Log Levels (Priority Order):**

| Level   | Value | Description                                      | Use Case                          |
|---------|-------|--------------------------------------------------|-----------------------------------|
| DEBUG   | 0     | Trace execution, variable values, control flow   | Development, troubleshooting      |
| INFO    | 1     | General informational messages                   | Monitoring normal operations      |
| WARN    | 2     | Warning messages, potential issues               | Production default                |
| ERROR   | 3     | Error conditions, recoverable failures           | Production monitoring             |
| FATAL   | 4     | Fatal errors, unrecoverable failures             | Critical failures only            |

**Examples:**

```bash
CLAUDE_DEBUG_LEVEL=DEBUG ./hook-lifecycle.sh pre-exec

CLAUDE_DEBUG_LEVEL=ERROR ./hook-lifecycle.sh post-exec
```

#### `CLAUDE_SAVE_LOGS`

Preserves logs after session ends (prevents automatic cleanup).

**Values:** `0` (disabled), `1` (enabled)

**Default:** `0`

```bash
export CLAUDE_SAVE_LOGS=1

export CLAUDE_SAVE_LOGS=0
```

#### `CLAUDE_SESSION_PID`

Session process ID used for file naming.

**Default:** `$$` (current shell PID)

```bash
export CLAUDE_SESSION_PID=12345
```

**Derived Files:**

- Log file: `/tmp/claude-session-${CLAUDE_SESSION_PID}.log`
- Error journal: `/tmp/claude-errors-${CLAUDE_SESSION_PID}.jsonl`
- Session file: `/tmp/claude-session-${CLAUDE_SESSION_PID}.json`

#### `CLAUDE_SESSION_FILE`

Explicit path to session JSON file (overrides auto-detection).

```bash
export CLAUDE_SESSION_FILE=/tmp/custom-session.json
```

### Marketplace-Specific Variables

#### `PLUGIN_NAME`

Current plugin name (set automatically by hooks).

```bash
export PLUGIN_NAME=my-plugin
```

#### `HOOK_NAME`

Current hook name (set automatically by hooks).

```bash
export HOOK_NAME=pre-exec
```

#### `LOG_FILE`

Custom log file path (overrides default).

**Default:** `/tmp/claude-session-${CLAUDE_SESSION_PID}.log`

```bash
export LOG_FILE=/var/log/my-plugin.log
```

#### `ERROR_JOURNAL`

Custom error journal path (overrides default).

**Default:** `/tmp/claude-errors-${CLAUDE_SESSION_PID}.jsonl`

```bash
export ERROR_JOURNAL=/var/log/my-plugin-errors.jsonl
```

## Real-Time Log Monitoring

### Monitor Session Logs

Track logs in real-time as hooks execute:

```bash
tail -f /tmp/claude-session-$$.log

tail -f /tmp/claude-session-$(pgrep -f claude).log
```

**Filter by log level:**

```bash
tail -f /tmp/claude-session-$$.log | grep '\[ERROR\]'

tail -f /tmp/claude-session-$$.log | grep '\[WARN\]\|\[ERROR\]\|\[FATAL\]'

tail -f /tmp/claude-session-$$.log | grep '\[DEBUG\]' | grep 'session-management'
```

**Filter by plugin:**

```bash
tail -f /tmp/claude-session-$$.log | grep '\[my-plugin\]'
```

**Filter by component:**

```bash
tail -f /tmp/claude-session-$$.log | grep '\[pre-exec\]'

tail -f /tmp/claude-session-$$.log | grep '\[session-management\]'
```

### Monitor Error Journal

Watch for errors in real-time:

```bash
tail -f /tmp/claude-errors-$$.jsonl

tail -f /tmp/claude-errors-$$.jsonl | jq '.'

tail -f /tmp/claude-errors-$$.jsonl | jq 'select(.level == "ERROR")'

tail -f /tmp/claude-errors-$$.jsonl | jq 'select(.level == "FATAL")'
```

### Monitor Multiple Files

Monitor logs and errors simultaneously:

```bash
tail -f /tmp/claude-session-$$.log /tmp/claude-errors-$$.jsonl

multitail /tmp/claude-session-$$.log /tmp/claude-errors-$$.jsonl
```

### Enable Debug Output

Run hooks with maximum verbosity:

```bash
CLAUDE_DEBUG_LEVEL=DEBUG CLAUDE_SAVE_LOGS=1 ./hook-lifecycle.sh pre-exec

CLAUDE_DEBUG_LEVEL=DEBUG bash -x ./hook-lifecycle.sh pre-exec
```

## Error Investigation

### Query Error Journal

The error journal is a JSONL (JSON Lines) file containing structured error data.

#### Basic Queries

**View all errors:**

```bash
cat /tmp/claude-errors-$$.jsonl | jq '.'
```

**Count errors:**

```bash
wc -l /tmp/claude-errors-$$.jsonl

cat /tmp/claude-errors-$$.jsonl | jq -s 'length'
```

**View last 10 errors:**

```bash
tail -n 10 /tmp/claude-errors-$$.jsonl | jq '.'
```

#### Filter by Severity

**Fatal errors only:**

```bash
cat /tmp/claude-errors-$$.jsonl | jq 'select(.level == "FATAL")'
```

**Errors and warnings:**

```bash
cat /tmp/claude-errors-$$.jsonl | jq 'select(.level == "ERROR" or .level == "WARN")'
```

**Errors excluding warnings:**

```bash
cat /tmp/claude-errors-$$.jsonl | jq 'select(.level == "ERROR")'
```

#### Filter by Plugin/Hook

**Errors from specific plugin:**

```bash
cat /tmp/claude-errors-$$.jsonl | jq 'select(.plugin == "my-plugin")'
```

**Errors from specific hook:**

```bash
cat /tmp/claude-errors-$$.jsonl | jq 'select(.hook == "pre-exec")'
```

**Errors from plugin and hook:**

```bash
cat /tmp/claude-errors-$$.jsonl | jq 'select(.plugin == "my-plugin" and .hook == "pre-exec")'
```

#### Filter by Error Code

**Specific error code:**

```bash
cat /tmp/claude-errors-$$.jsonl | jq 'select(.code == "SESSION_INIT_FAILED")'
```

**Error codes matching pattern:**

```bash
cat /tmp/claude-errors-$$.jsonl | jq 'select(.code | contains("SESSION"))'
```

#### Filter by Time Range

**Errors in last hour:**

```bash
cat /tmp/claude-errors-$$.jsonl | jq --arg cutoff "$(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%SZ)" 'select(.timestamp > $cutoff)'
```

**Errors after specific timestamp:**

```bash
cat /tmp/claude-errors-$$.jsonl | jq 'select(.timestamp > "2025-11-22T10:00:00Z")'
```

#### Analyze Error Patterns

**Group errors by code:**

```bash
cat /tmp/claude-errors-$$.jsonl | jq -s 'group_by(.code) | map({code: .[0].code, count: length}) | sort_by(.count) | reverse'
```

**Group errors by plugin:**

```bash
cat /tmp/claude-errors-$$.jsonl | jq -s 'group_by(.plugin) | map({plugin: .[0].plugin, count: length}) | sort_by(.count) | reverse'
```

**Extract unique error codes:**

```bash
cat /tmp/claude-errors-$$.jsonl | jq -r '.code' | sort -u
```

#### Examine Stack Traces

**View stack traces for fatal errors:**

```bash
cat /tmp/claude-errors-$$.jsonl | jq 'select(.level == "FATAL") | {code: .code, message: .message, stack: .stack}'
```

**Find errors with specific stack frames:**

```bash
cat /tmp/claude-errors-$$.jsonl | jq 'select(.stack | any(contains("init_session")))'
```

#### Export Error Reports

**Generate error summary:**

```bash
cat /tmp/claude-errors-$$.jsonl | jq -s '{
  total_errors: length,
  by_level: group_by(.level) | map({level: .[0].level, count: length}),
  by_plugin: group_by(.plugin) | map({plugin: .[0].plugin, count: length}),
  by_code: group_by(.code) | map({code: .[0].code, count: length})
}'
```

**Export to CSV:**

```bash
cat /tmp/claude-errors-$$.jsonl | jq -r '[.timestamp, .plugin, .hook, .level, .code, .message] | @csv' > errors.csv
```

## Session Inspection

### View Session State

**Pretty-print session JSON:**

```bash
cat /tmp/claude-session-$$.json | jq '.'
```

**View session metadata:**

```bash
cat /tmp/claude-session-$$.json | jq '.metadata'
```

**View specific plugin state:**

```bash
cat /tmp/claude-session-$$.json | jq '.plugins["my-plugin"]'
```

### Query Session Data

**Check if recommendation was shown:**

```bash
cat /tmp/claude-session-$$.json | jq '.plugins["my-plugin"].recommendations_shown["skill-name"]'
```

**Check validation status:**

```bash
cat /tmp/claude-session-$$.json | jq '.validations_passed["file-path"]["validation-name"]'
```

**View custom data:**

```bash
cat /tmp/claude-session-$$.json | jq '.custom_data'
```

### Calculate Session Age

**Get session start time:**

```bash
cat /tmp/claude-session-$$.json | jq -r '.started_at'
```

**Calculate session age (manual):**

```bash
start_time=$(cat /tmp/claude-session-$$.json | jq -r '.started_at')
start_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$start_time" +%s 2>/dev/null || date -d "$start_time" +%s)
now_epoch=$(date +%s)
age=$((now_epoch - start_epoch))
echo "Session age: $age seconds"
```

**Using session management functions:**

```bash
source ./session-management.sh
SESSION_FILE=/tmp/claude-session-$$.json
get_session_age
```

### List Active Sessions

**Find all session files:**

```bash
ls -lh /tmp/claude-session-*.json
```

**Find sessions with PIDs:**

```bash
for f in /tmp/claude-session-*.json; do
  pid=$(basename "$f" .json | sed 's/claude-session-//')
  if ps -p "$pid" >/dev/null 2>&1; then
    echo "ACTIVE: $f (PID $pid)"
  else
    echo "STALE: $f (PID $pid - process not running)"
  fi
done
```

**View session summary:**

```bash
for f in /tmp/claude-session-*.json; do
  echo "=== $f ==="
  jq '{session_id, started_at, plugins: (.plugins | keys)}' "$f"
  echo
done
```

### Clean Up Stale Sessions

**Manually remove stale sessions:**

```bash
for f in /tmp/claude-session-*.json; do
  pid=$(basename "$f" .json | sed 's/claude-session-//')
  if ! ps -p "$pid" >/dev/null 2>&1; then
    echo "Removing stale session: $f"
    rm -f "$f" "${f}.lock"
    rmdir "${f}.lock.d" 2>/dev/null || true
  fi
done
```

**Using session management functions:**

```bash
source ./session-management.sh
cleanup_stale_sessions 86400
```

## Common Issues

### Issue 1: No Logs Appearing

**Symptoms:**
- Log file is empty or missing
- No output during hook execution

**Diagnosis:**

```bash
ls -lh /tmp/claude-session-*.log

echo "Current PID: $$"
echo "Expected log file: /tmp/claude-session-$$.log"

echo "CLAUDE_DEBUG_LEVEL=${CLAUDE_DEBUG_LEVEL:-not set}"
```

**Solutions:**

1. **Check log level:**
   ```bash
   export CLAUDE_DEBUG_LEVEL=DEBUG
   ```

2. **Verify log file path:**
   ```bash
   export LOG_FILE=/tmp/test-session.log
   source ./logging.sh
   log_info "Test message"
   cat /tmp/test-session.log
   ```

3. **Check file permissions:**
   ```bash
   touch /tmp/claude-session-$$.log
   chmod 644 /tmp/claude-session-$$.log
   ```

4. **Test logging directly:**
   ```bash
   source ./logging.sh
   CLAUDE_DEBUG_LEVEL=DEBUG log_debug "Debug test"
   CLAUDE_DEBUG_LEVEL=DEBUG log_info "Info test"
   cat "$LOG_FILE"
   ```

### Issue 2: Errors Not Being Recorded

**Symptoms:**
- Error journal is empty
- Errors occur but not logged

**Diagnosis:**

```bash
ls -lh /tmp/claude-errors-*.jsonl

echo "ERROR_JOURNAL=${ERROR_JOURNAL:-not set}"

cat /tmp/claude-errors-$$.jsonl 2>&1
```

**Solutions:**

1. **Test error reporting:**
   ```bash
   source ./error-reporting.sh
   report_error "TEST_ERROR" "Test error message" '{"detail": "test"}'
   cat "$ERROR_JOURNAL" | jq '.'
   ```

2. **Check jq availability:**
   ```bash
   command -v jq || echo "jq not installed"
   jq --version
   ```

3. **Verify error journal path:**
   ```bash
   export ERROR_JOURNAL=/tmp/test-errors.jsonl
   source ./error-reporting.sh
   report_error "TEST" "Test"
   cat /tmp/test-errors.jsonl
   ```

4. **Check file permissions:**
   ```bash
   touch /tmp/claude-errors-$$.jsonl
   chmod 644 /tmp/claude-errors-$$.jsonl
   ```

### Issue 3: Session Data Not Persisting

**Symptoms:**
- Session file missing or corrupted
- Session values not saved

**Diagnosis:**

```bash
ls -lh /tmp/claude-session-*.json

cat /tmp/claude-session-$$.json 2>&1

echo "CLAUDE_SESSION_FILE=${CLAUDE_SESSION_FILE:-not set}"
echo "CLAUDE_SESSION_PID=${CLAUDE_SESSION_PID:-not set}"
```

**Solutions:**

1. **Initialize session manually:**
   ```bash
   source ./session-management.sh
   init_session "test-plugin"
   cat "$SESSION_FILE" | jq '.'
   ```

2. **Test session operations:**
   ```bash
   source ./session-management.sh
   init_session "test-plugin"
   set_session_value "test_key" '"test_value"'
   get_session_value "test_key"
   ```

3. **Check jq installation:**
   ```bash
   command -v jq || echo "jq not installed - required for session management"
   ```

4. **Verify write permissions:**
   ```bash
   touch /tmp/claude-session-$$.json
   chmod 644 /tmp/claude-session-$$.json
   ```

5. **Check for lock conflicts:**
   ```bash
   ls -lh /tmp/claude-session-*.lock* 2>/dev/null
   rm -f /tmp/claude-session-$$.json.lock
   rmdir /tmp/claude-session-$$.json.lock.d 2>/dev/null || true
   ```

### Issue 4: Lock Acquisition Timeouts

**Symptoms:**
- "Failed to acquire lock" errors
- Hook execution hangs

**Diagnosis:**

```bash
ls -lh /tmp/*.lock /tmp/*.lock.d 2>/dev/null

ps aux | grep -E "claude|hook"

lsof /tmp/claude-session-*.lock 2>/dev/null
```

**Solutions:**

1. **Remove stale locks:**
   ```bash
   rm -f /tmp/claude-session-*.lock
   rm -rf /tmp/claude-session-*.lock.d
   ```

2. **Increase timeout:**
   ```bash
   source ./session-management.sh
   acquire_lock "/tmp/test-file.json" 10
   ```

3. **Check for deadlocked processes:**
   ```bash
   ps aux | grep hook
   pkill -9 -f hook-lifecycle.sh
   ```

4. **Use platform-specific locking:**
   ```bash
   command -v flock && echo "Using flock" || echo "Using mkdir fallback"
   ```

### Issue 5: Platform Compatibility Issues

**Symptoms:**
- Commands fail on macOS but work on Linux (or vice versa)
- Date parsing errors

**Diagnosis:**

```bash
uname -s

date --version 2>&1

stat --version 2>&1
```

**Solutions:**

1. **Use platform-compat functions:**
   ```bash
   source ./platform-compat.sh
   get_current_epoch
   get_timestamp_epoch "2025-11-22T10:00:00Z"
   get_file_age "/tmp/test-file.json"
   ```

2. **Check platform detection:**
   ```bash
   source ./platform-compat.sh
   echo "Platform: $(uname -s | tr '[:upper:]' '[:lower:]')"
   ```

3. **Test date commands:**
   ```bash
   date -u +%Y-%m-%dT%H:%M:%SZ
   date +%s
   ```

### Issue 6: Missing Dependencies

**Symptoms:**
- "command not found" errors
- Unexpected behavior

**Diagnosis:**

```bash
command -v jq || echo "jq missing"
command -v flock || echo "flock missing"
command -v bash || echo "bash missing"

bash --version | head -1

jq --version
```

**Solutions:**

1. **Install jq:**
   ```bash
   brew install jq

   sudo apt-get install jq

   sudo yum install jq
   ```

2. **Install util-linux (for flock):**
   ```bash
   brew install util-linux

   sudo apt-get install util-linux
   ```

3. **Upgrade bash:**
   ```bash
   bash --version
   brew install bash
   ```

## Debugging Workflow

### Step 1: Enable Debug Logging

```bash
export CLAUDE_DEBUG_LEVEL=DEBUG
export CLAUDE_SAVE_LOGS=1
```

### Step 2: Monitor Logs in Real-Time

```bash
tail -f /tmp/claude-session-$$.log &
tail -f /tmp/claude-errors-$$.jsonl | jq '.' &
```

### Step 3: Run Hook

```bash
./hook-lifecycle.sh pre-exec < input.json
```

### Step 4: Inspect Results

**Check logs:**

```bash
grep '\[ERROR\]\|\[FATAL\]' /tmp/claude-session-$$.log
```

**Check errors:**

```bash
cat /tmp/claude-errors-$$.jsonl | jq 'select(.level == "ERROR" or .level == "FATAL")'
```

**Check session state:**

```bash
cat /tmp/claude-session-$$.json | jq '.'
```

### Step 5: Analyze Errors

**Group by error code:**

```bash
cat /tmp/claude-errors-$$.jsonl | jq -s 'group_by(.code) | map({code: .[0].code, count: length, example: .[0].message})'
```

**View stack traces:**

```bash
cat /tmp/claude-errors-$$.jsonl | jq '.stack'
```

### Step 6: Clean Up

```bash
rm -f /tmp/claude-session-$$.log /tmp/claude-errors-$$.jsonl /tmp/claude-session-$$.json
```

### Troubleshooting Decision Tree

```
Hook not working?
├─ No logs appearing?
│  ├─ Check CLAUDE_DEBUG_LEVEL
│  ├─ Check log file path
│  └─ Test logging directly
├─ Errors but not recorded?
│  ├─ Check ERROR_JOURNAL path
│  ├─ Verify jq installed
│  └─ Test error reporting directly
├─ Session data not persisting?
│  ├─ Check CLAUDE_SESSION_FILE
│  ├─ Verify jq installed
│  ├─ Check write permissions
│  └─ Remove stale locks
├─ Lock acquisition timeouts?
│  ├─ Remove stale locks
│  ├─ Increase timeout
│  └─ Check for deadlocked processes
├─ Platform compatibility issues?
│  ├─ Use platform-compat.sh
│  ├─ Check date command
│  └─ Verify bash version
└─ Missing dependencies?
   ├─ Install jq
   ├─ Install flock (util-linux)
   └─ Upgrade bash
```

### Advanced Debugging Techniques

#### Trace Hook Execution

```bash
set -x
CLAUDE_DEBUG_LEVEL=DEBUG ./hook-lifecycle.sh pre-exec
set +x
```

#### Capture Function Call Trace

```bash
export PS4='+ ${BASH_SOURCE}:${LINENO}:${FUNCNAME[0]}: '
bash -x ./hook-lifecycle.sh pre-exec 2>&1 | tee hook-trace.log
```

#### Profile Hook Performance

```bash
time CLAUDE_DEBUG_LEVEL=INFO ./hook-lifecycle.sh pre-exec

/usr/bin/time -v ./hook-lifecycle.sh pre-exec 2>&1
```

#### Debug Specific Function

```bash
source ./session-management.sh

set -x
init_session "test-plugin"
set +x

cat "$SESSION_FILE" | jq '.'
```

#### Isolate Component Issues

```bash
source ./logging.sh
CLAUDE_DEBUG_LEVEL=DEBUG log_info "Test logging"
cat "$LOG_FILE"

source ./error-reporting.sh
report_error "TEST" "Test error"
cat "$ERROR_JOURNAL" | jq '.'

source ./session-management.sh
init_session "test"
get_session_value "session_id"
```

## Additional Resources

- [Session Management v2 Design](SESSION-MANAGEMENT-V2-DESIGN.md)
- [Hook Lifecycle Documentation](../hook-templates/README.md)
- [Platform Compatibility Notes](../platform-compat.sh)
