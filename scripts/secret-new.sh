#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 4 ]]; then
  echo "usage: secret-new.sh FILE NAME NAMESPACE|- KEY..." >&2
  exit 2
fi

file=$1 name=$2 namespace=$3
shift 3

if [[ $file != *.sops.yaml ]]; then
  echo "FILE must end in .sops.yaml" >&2
  exit 1
fi
if [[ -e $file ]]; then
  echo "$file already exists" >&2
  exit 1
fi

{
  echo "apiVersion: v1"
  echo "kind: Secret"
  echo "metadata:"
  echo "  name: $name"
  [[ $namespace == "-" ]] || echo "  namespace: $namespace"
  echo "stringData:"
  for key in "$@"; do
    read -r -s -p "$key: " value </dev/tty
    echo >&2
    printf '  %s: %s\n' "$key" "$(jq -Rn --arg v "$value" '$v')"
  done
} | sops encrypt --filename-override "$file" --input-type yaml --output-type yaml /dev/stdin >"$file.tmp"

mv "$file.tmp" "$file"
echo "wrote $file" >&2
