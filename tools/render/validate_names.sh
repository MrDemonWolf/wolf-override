#!/usr/bin/env bash
# Validate cache directory names and screen dimensions before render.sh touches disk.
# Usage: source this file, or run validate_names.sh --self-test. No environment variables.

## A single path segment: letters, digits, dot, underscore and hyphen, and never "." or "..".
## $1 is the value, $2 what it is called in the message (default "name").
check_name() {
  local value="$1" what="${2:-name}"
  if [[ ! "$value" =~ ^[A-Za-z0-9._-]+$ || "$value" == "." || "$value" == ".." ]]; then
    echo "$what '$value' must use only A-Z a-z 0-9 . _ - and cannot be . or .." >&2
    return 1
  fi
}

## A window or screen size in pixels, WIDTHxHEIGHT, such as 1280x720.
check_size() {
  if [[ ! "$1" =~ ^[0-9]+x[0-9]+$ ]]; then
    echo "size '$1' must be WIDTHxHEIGHT in pixels, such as 1280x720" >&2
    return 1
  fi
}

## Checks every accept and refuse case above; prints one line per failure and returns 1 on any.
validate_names_self_test() {
  local failures=0 value got
  _expect() {  # $1 = want (ok|no), the rest = the check and its value
    local want="$1"; shift
    if "$@" 2>/dev/null; then got=ok; else got=no; fi
    if [[ "$got" != "$want" ]]; then
      echo "SELF-TEST FAIL: $* gave $got, want $want" >&2
      failures=$((failures + 1))
    fi
  }
  for value in default capture-1 a.b_c-9 ..x x..; do _expect ok check_name "$value"; done
  for value in "" . .. ../x a/b "a b" '$(x)' "a*" x/..; do _expect no check_name "$value"; done
  for value in 960x540 2340x1080 1x1; do _expect ok check_size "$value"; done
  for value in "" 1280 1280x 1280X720 -1x2 1280x720x1 "1280 x720" ../1x1; do _expect no check_size "$value"; done
  unset -f _expect
  if [[ $failures -gt 0 ]]; then
    echo "validate_names self-test failed ($failures)" >&2
    return 1
  fi
  echo "validate_names self-test passed: names and sizes"
}

# Sourced: define the checks only. Run as a script: --self-test.
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  if [[ "${1:-}" == "--self-test" ]]; then
    validate_names_self_test
    exit $?
  fi
  echo "usage: $0 --self-test   (or source it for check_name, check_size)" >&2
  exit 64
fi
