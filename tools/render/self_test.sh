#!/usr/bin/env bash
# No-Docker self-test of tools/render/render.sh's exit status and name checks, for CI and for anyone
# changing render.sh. It runs the shared name checks' own self-test (validate_names.sh --self-test),
# then runs render.sh against a stand-in `docker` placed first on PATH that plays Godot's part: it
# exits with a chosen status for the import and for the render run, and writes a file to the run's
# output folder, so the test sees what render.sh reports and copies back without a container.
#
# Checks: a render run's status is render.sh's (0, a crash's 3, a timeout's 124 with its message) and
# the output is copied back even after a failure (Codex review finding M1); a failing final import
# fails the run, while a first import that only the second pass gets through does not (low finding
# render.sh:62,65); a bad --name, --screen or --timeout exits 64 before any folder or docker call
# (finding M2). Needs bash, rsync and a project.godot-shaped folder it makes itself; nothing else.
#
# Usage: tools/render/self_test.sh    (exit 0 when every check passes)
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
bash "$here/validate_names.sh" --self-test

scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT
# The cache is cache/render; cache/out/canary stands for a folder beside it. Before the name check,
# --name .. made render.sh's cache cache/ itself, and its find -delete emptied cache/out.
mkdir -p "$scratch/bin" "$scratch/project" "$scratch/cache/render" "$scratch/cache/out"
touch "$scratch/project/project.godot" "$scratch/cache/out/canary"

# The stand-in docker. STUB_IMPORT_FAILS is how many import passes fail (status 1) before one passes;
# STUB_RUN is the render run's status. Every call is logged to calls.log, one line each.
cat > "$scratch/bin/docker" <<'STUB'
#!/usr/bin/env bash
echo "$*" >> "$STUB_DIR/calls.log"
[[ "$1" == "image" ]] && exit 0
host=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -v) host="${2%:/work}"; shift 2 ;;
    --import) n=$(( $(cat "$STUB_DIR/imports" 2>/dev/null || echo 0) + 1 )); echo "$n" > "$STUB_DIR/imports"
              [[ $n -le ${STUB_IMPORT_FAILS:-0} ]] && exit 1; mkdir -p "$host/project/.godot"; exit 0 ;;
    *) shift ;;
  esac
done
echo "stub godot run"
echo out > "$host/out/stub.txt"
exit "${STUB_RUN:-0}"
STUB
chmod +x "$scratch/bin/docker"

failures=0
## Runs render.sh with the stand-in. $1 = the status it must exit with, $2 = text stderr must hold
## ("" for none), the rest = render.sh's options. Clears the call log, import count and output first.
expect() {
  local want="$1" text="$2" got=0
  shift 2
  rm -rf "$scratch/out" "$scratch/calls.log" "$scratch/imports" "$scratch/err"
  PATH="$scratch/bin:$PATH" STUB_DIR="$scratch" WOLF_RENDER_CACHE="$scratch/cache/render" \
    bash "$here/render.sh" "$@" "$scratch/project" "$scratch/out" -- --quit > /dev/null 2> "$scratch/err" || got=$?
  if [[ $got -ne $want ]]; then
    echo "SELF-TEST FAIL: render.sh $* exited $got, want $want ($(tr '\n' ' ' < "$scratch/err"))" >&2
    failures=$((failures + 1))
  elif [[ -n "$text" ]] && ! grep -qF -e "$text" "$scratch/err"; then
    echo "SELF-TEST FAIL: render.sh $* did not say '$text'" >&2
    failures=$((failures + 1))
  fi
}
## Fails the test with $1 unless the command after it succeeds.
check() {
  local why="$1"
  shift
  "$@" || { echo "SELF-TEST FAIL: $why" >&2; failures=$((failures + 1)); }
}

STUB_RUN=0 expect 0 "" --name st
check "a passing run's output was not copied back" test -f "$scratch/out/stub.txt"
STUB_RUN=3 expect 3 "" --name st
check "a crashed run's output was not copied back" test -f "$scratch/out/stub.txt"
STUB_RUN=124 expect 124 "Godot was stopped after 5s" --name st --timeout 5
# The cache "st" has its .godot now, so there is one import pass, and it must pass.
STUB_IMPORT_FAILS=1 expect 1 "the import failed with status 1" --name st
check "a run went ahead after its import failed" test ! -e "$scratch/out/stub.txt"
# A fresh cache imports twice; a failing first pass is forgiven when the second passes.
STUB_IMPORT_FAILS=1 expect 0 "" --name fresh
STUB_IMPORT_FAILS=2 expect 1 "the import failed" --name fresh2
for bad in .. . ../keep "a/b" ""; do
  expect 64 "--name '$bad'" --name "$bad"
  check "--name '$bad' reached docker" test ! -e "$scratch/calls.log"
done
check "a refused --name touched the folder beside the cache" test -f "$scratch/cache/out/canary"
expect 64 "size '1280' must be" --name st --screen 1280
expect 64 "--timeout takes" --name st --timeout 0
expect 64 "--keyboard takes" --name st --keyboard "us;x"

if [[ $failures -gt 0 ]]; then
  echo "render.sh self-test failed ($failures)" >&2
  exit 1
fi
echo "render.sh self-test passed: run status kept (0, crash, timeout), output copied after a failure, final import judged, bad names refused before any folder or docker call"
