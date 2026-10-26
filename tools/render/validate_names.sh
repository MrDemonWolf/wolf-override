#!/usr/bin/env bash
# Shared checks for the names that tools/render/render.sh and scripts/parity/run.sh join into paths.
# A job name becomes a cache folder that rsync --delete, find -delete and docker -v act on, and a
# route, variant and size become a capture folder that rm -rf clears, so a name such as ".." or
# "a/../../x" would delete or overwrite folders outside the cache (Codex review finding M2, October
# 20, 2026). Both scripts source this file and call these checks before they touch any folder.
#
# Each check takes the value, prints why it is refused to stderr and returns 1, or returns 0. None of
# them exits, so a caller decides its own exit status (render.sh and run.sh use 64, EX_USAGE).
#
#   source tools/render/validate_names.sh
#   check_name JOB "--name" && check_route R1 && check_variant kb-fx && check_size 1280x720
#
# Run directly with --self-test to check the checks themselves; it needs no Docker or Godot, so CI
# runs it (tools/render/self_test.sh runs it with the render.sh checks).

## The routes scripts/parity/capture.gd plays; it refuses any other route itself (its ROUTES).
PARITY_ROUTES="R1 R2 R3 R4"
## The capture variants scripts/parity/capture.gd knows (its VARIANTS): keyboard with effects,
## keyboard calm (effects off and Reduced Motion), touch layout with effects.
PARITY_VARIANTS="kb-fx kb-calm touch-fx"

## A single path segment: letters, digits, dot, underscore and hyphen, and never "." or "..".
## $1 is the value, $2 what it is called in the message (default "name").
check_name() {
  local value="$1" what="${2:-name}"
  if [[ ! "$value" =~ ^[A-Za-z0-9._-]+$ || "$value" == "." || "$value" == ".." ]]; then
    echo "$what '$value' must use only A-Z a-z 0-9 . _ - and cannot be . or .." >&2
    return 1
  fi
}

## A word of the space-separated list $2; $3 names the kind in the message.
_check_listed() {
  local value="$1" list="$2" what="$3" item
  for item in $list; do
    [[ "$value" == "$item" ]] && return 0
  done
  echo "unknown $what '$value' (expected one of: $list)" >&2
  return 1
}

## One of PARITY_ROUTES.
check_route() { _check_listed "$1" "$PARITY_ROUTES" route; }

## One of PARITY_VARIANTS.
check_variant() { _check_listed "$1" "$PARITY_VARIANTS" variant; }

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
  for value in default lighter-parity-R1 a.b_c-9 ..x x..; do _expect ok check_name "$value"; done
  for value in "" . .. ../x a/b "a b" '$(x)' "a*" x/..; do _expect no check_name "$value"; done
  for value in R1 R2 R3 R4; do _expect ok check_route "$value"; done
  for value in "" R0 R5 r1 "R1 R2" ../R1; do _expect no check_route "$value"; done
  for value in kb-fx kb-calm touch-fx; do _expect ok check_variant "$value"; done
  for value in "" kb touch-calm KB-FX ../kb-fx; do _expect no check_variant "$value"; done
  for value in 960x540 2340x1080 1x1; do _expect ok check_size "$value"; done
  for value in "" 1280 1280x 1280X720 -1x2 1280x720x1 "1280 x720" ../1x1; do _expect no check_size "$value"; done
  unset -f _expect
  if [[ $failures -gt 0 ]]; then
    echo "validate_names self-test failed ($failures)" >&2
    return 1
  fi
  echo "validate_names self-test passed: names, routes, variants and sizes"
}

# Sourced: define the checks only. Run as a script: --self-test.
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  if [[ "${1:-}" == "--self-test" ]]; then
    validate_names_self_test
    exit $?
  fi
  echo "usage: $0 --self-test   (or source it for check_name, check_route, check_variant, check_size)" >&2
  exit 64
fi
