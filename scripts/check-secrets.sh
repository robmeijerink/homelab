#!/usr/bin/env bash
set -euo pipefail

rc=0
for f in "$@"; do
  [[ -f $f ]] || continue
  base=${f##*/}
  [[ $base == .sops.yaml ]] && continue

  case $f in
    *.yaml | *.yml | *.json) ;;
    *) continue ;;
  esac

  if ! docs=$(yq -r '.kind // "" , ((.items // [])[]? | .kind // "")' "$f" 2>&1); then
    echo "cannot parse: $f" >&2
    rc=1
    continue
  fi

  if [[ $f == *.sops.yaml || $f == *.sops.yml || $f == *.sops.json ]]; then
    if [[ $(yq -r 'has("sops")' "$f" | sort -u) != true ]]; then
      echo "not encrypted, no sops metadata: $f" >&2
      rc=1
      continue
    fi
    plain=$(yq -r '[(.data // {}), (.stringData // {})] | map(to_entries) | flatten | map(select((.value | tostring) | test("^ENC\\[") | not)) | length' "$f" | awk '{n += $1} END {print n + 0}')
    if [[ $plain -gt 0 ]]; then
      echo "plaintext value in $f" >&2
      rc=1
    fi
  elif grep -qx 'Secret' <<<"$docs"; then
    echo "kind: Secret outside a *.sops.yaml file: $f" >&2
    rc=1
  fi
done
exit "$rc"
