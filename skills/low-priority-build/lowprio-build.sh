#!/usr/bin/env bash
# Runs a heavy build (flutter build, gradlew, …) without slowing the computer
# down, on Windows (Git Bash), Linux and macOS:
#   - lower priority, set as the process is created, so every child — dart,
#     gradle, the Kotlin compiler, R8 — inherits it: Windows' below-normal
#     (cmd's `start /belownormal`), elsewhere `nice -n 10`, plus on Linux
#     `ionice -c2 -n7` (lowest best-effort disk priority) when available;
#   - Gradle capped at N workers (default 4), one project at a time, and no
#     shared daemon, so an earlier daemon started at normal priority isn't
#     reused.
# Memory stays what the project's android/gradle.properties gives Gradle.
#
# Usage:
#   lowprio-build.sh -C <project dir> [-w <workers>] [-l <log file>] -- <command> [args…]
# Example:
#   lowprio-build.sh -C ~/Repos/app -l /tmp/app.log -- \
#     flutter build apk --flavor dev -t lib/main_dev.dart --target-platform android-arm,android-arm64
#
# The command's output goes to the log (default: <project dir>/build/lowprio-build.log),
# which ends with a line `EXIT <code>`. The script exits with the command's code
# and prints the log's last 25 lines.

set -euo pipefail

workers=4
dir=""
log=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -C) dir="$2"; shift 2 ;;
    -w) workers="$2"; shift 2 ;;
    -l) log="$2"; shift 2 ;;
    --) shift; break ;;
    -h|--help) sed -n '2,21p' "$0"; exit 0 ;;
    *) echo "unknown option: $1 (use -- before the command)" >&2; exit 2 ;;
  esac
done

if [[ -z "$dir" || $# -eq 0 ]]; then
  echo "usage: lowprio-build.sh -C <project dir> [-w workers] [-l log] -- <command> [args…]" >&2
  exit 2
fi
if ! [[ "$workers" =~ ^[1-9][0-9]*$ ]]; then
  echo "workers must be a positive number: $workers" >&2
  exit 2
fi

[[ -d "$dir" ]] || { echo "no such directory: $dir" >&2; exit 2; }
[[ -n "$log" ]] || { mkdir -p "$dir/build"; log="$dir/build/lowprio-build.log"; }
mkdir -p "$(dirname "$log")"
: > "$log"

gradle_opts="-Dorg.gradle.workers.max=$workers -Dorg.gradle.daemon=false -Dorg.gradle.parallel=false"

case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*) ;;  # Windows: below, through cmd.
  *)
    # Linux / macOS: run the command directly, so arguments pass through
    # untouched. The log is opened here, before the cd, so a relative -l works.
    prio=(nice -n 10)
    if command -v ionice > /dev/null 2>&1 && ionice -c2 -n7 true 2> /dev/null; then
      prio=(ionice -c2 -n7 "${prio[@]}")
    fi
    set +e
    (cd "$dir" && GRADLE_OPTS="$gradle_opts" "${prio[@]}" "$@") > "$log" 2>&1
    code=$?
    set -e
    echo "EXIT $code" >> "$log"
    tail -25 "$log"
    exit "$code"
    ;;
esac

dir_win="$(cygpath -w "$(cd "$dir" && pwd)")"
log_win="$(cygpath -w "$(cd "$(dirname "$log")" && pwd)")\\$(basename "$log")"

# The command line, each argument quoted when it holds a space. Inside the
# generated batch file `%` must be doubled.
cmdline=""
for arg in "$@"; do
  if [[ "$arg" == *" "* ]]; then arg="\"$arg\""; fi
  cmdline+="${cmdline:+ }$arg"
done
cmdline="${cmdline//%/%%}"

script="$(mktemp --suffix=.cmd)"
trap 'rm -f "$script"' EXIT
cat > "$script" <<EOF
@echo off
cd /d "$dir_win"
set GRADLE_OPTS=$gradle_opts
start "" /belownormal /b /wait cmd /c "$cmdline > "$log_win" 2>&1"
set code=%ERRORLEVEL%
echo EXIT %code% >> "$log_win"
exit /b %code%
EOF

set +e
cmd //c "$(cygpath -w "$script")"
code=$?
set -e

tail -25 "$log"
exit "$code"
