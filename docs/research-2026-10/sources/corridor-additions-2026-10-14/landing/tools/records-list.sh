#!/usr/bin/env bash
# Prints the add7 track files filed as records (run from real-slice/add7).
find beacons crank door plume integrate fix1 fix2 fix3 fix4 codex \
  \( -path '*/work' -o -path '*/game-*' -o -name 'game' -o -path '*/base-game' -o -path '*/test-game' -o -path '*/shots' -o -path '*/qa' -o -path '*/probe' -o -path '*/negtest' -o -path '*/logs' -o -path '*/mock' -o -path '*/__pycache__' -o -path '*/ref-round6' -o -path '*/tmp-flat' \) -prune -o -type f -print |
while read -r f; do
  case "$f" in
    */layers/*.png|*/layer/*.png|*/scan/*.png) continue ;;
    *.log) case "$f" in */codex/*) ;; *) continue ;; esac ;;
  esac
  sz=$(stat -f %z "$f")
  case "$f" in
    */codex/*|crank/raw/*) echo "$f" ;;
    *) [ "$sz" -le 1500000 ] && echo "$f" ;;
  esac
done
