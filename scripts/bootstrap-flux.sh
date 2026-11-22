#!/usr/bin/env bash
set -euo pipefail

context=${KUBE_CONTEXT:-homelab}
dir=bootstrap/flux-operator
key=${SOPS_AGE_KEY_FILE:-$HOME/.config/sops/age/keys.txt}
k() { kubectl --context "$context" "$@"; }

[[ -f $key ]] || { echo "age key not found: $key" >&2; exit 1; }

helm dependency build "$dir"
helm upgrade --install flux-operator "$dir" --namespace flux-system --create-namespace --kube-context "$context"
k -n flux-system rollout status deployment/flux-operator --timeout=5m

k -n flux-system create secret generic sops-age --from-file=age.agekey="$key" --dry-run=client -o yaml | k apply -f - >/dev/null

k apply -f kubernetes/flux/instance/flux-instance.yaml
k -n flux-system wait fluxinstance/flux --for=condition=Ready --timeout=10m
