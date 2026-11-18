#!/usr/bin/env bash
set -euo pipefail

rc=0
for f in "$@"; do
  [[ -f $f ]] || continue
  if [[ $f == *.sops.yaml || $f == *.sops.yml ]]; then
    if ! grep -q '^sops:' "$f"; then
      echo "not encrypted: $f" >&2
      rc=1
    fi
  elif grep -Eq '^kind:[[:space:]]*Secret[[:space:]]*$' "$f"; then
    echo "kind: Secret outside a *.sops.yaml file: $f" >&2
    rc=1
  fi
done
exit "$rc"
