#!/usr/bin/env bash

trap 'exit 0' PIPE

detect_platform() {
  case "$OSTYPE" in
    darwin*)
      echo "macos"
      ;;
    linux*)
      echo "linux"
      ;;
    msys*|cygwin*)
      echo "windows"
      ;;
    *)
      echo "unknown"
      ;;
  esac
}

is_remote_execution() {
  [[ "${CLAUDE_CODE_REMOTE:-}" == "true" ]]
}

get_execution_environment() {
  if is_remote_execution; then
    echo "remote"
  else
    echo "local"
  fi
}

get_timestamp_epoch() {
  local iso_timestamp="$1"

  case "$(detect_platform)" in
    macos)
      date -j -f "%Y-%m-%dT%H:%M:%SZ" "$iso_timestamp" "+%s" 2>/dev/null || echo "0"
      ;;
    linux|windows)
      date -d "$iso_timestamp" "+%s" 2>/dev/null || echo "0"
      ;;
    *)
      echo "0"
      ;;
  esac
}

get_current_epoch() {
  date "+%s"
}

get_timestamp_ms() {
  case "$(detect_platform)" in
    macos)
      echo $(($(date +%s) * 1000))
      ;;
    linux|windows)
      date +%s%3N 2>/dev/null || echo $(($(date +%s) * 1000))
      ;;
    *)
      echo $(($(date +%s) * 1000))
      ;;
  esac
}

format_timestamp() {
  local epoch="$1"

  case "$(detect_platform)" in
    macos)
      date -u -r "$epoch" "+%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo ""
      ;;
    linux|windows)
      date -u -d "@$epoch" "+%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo ""
      ;;
    *)
      echo ""
      ;;
  esac
}

check_dependencies() {
  local missing=()

  command -v jq >/dev/null || missing+=("jq")

  if [[ ${#missing[@]} -gt 0 ]]; then
    echo "Missing dependencies: ${missing[*]}" >&2
    return 1
  fi

  return 0
}

check_flock() {
  if command -v flock >/dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

suggest_flock_install() {
  case "$(detect_platform)" in
    macos)
      echo "flock not found. For better performance, install via: brew install util-linux" >&2
      ;;
    linux)
      echo "flock not found. Install via package manager (e.g., apt install util-linux)" >&2
      ;;
  esac
}

get_temp_dir() {
  if [[ -n "${TMPDIR:-}" ]]; then
    echo "${TMPDIR%/}"
  elif [[ -n "${TMP:-}" ]]; then
    echo "${TMP%/}"
  elif [[ -n "${TEMP:-}" ]]; then
    echo "${TEMP%/}"
  else
    echo "/tmp"
  fi
}

get_file_age() {
  local file="$1"

  if [[ ! -f "$file" ]]; then
    echo "0"
    return
  fi

  local modified
  case "$(detect_platform)" in
    macos)
      modified=$(stat -f %m "$file" 2>/dev/null || echo "0")
      ;;
    linux|windows)
      modified=$(stat -c %Y "$file" 2>/dev/null || echo "0")
      ;;
    *)
      echo "0"
      return
      ;;
  esac

  local now
  now=$(date +%s)
  echo $((now - modified))
}

sanitize_shell_arg() {
  local arg="$1"
  printf '%q' "$arg"
}
