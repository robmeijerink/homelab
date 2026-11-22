#!/usr/bin/env bash
set -euo pipefail

context=${KUBE_CONTEXT:-homelab}
dir=bootstrap/flux-operator
key=${SOPS_AGE_KEY_FILE:-$HOME/.config/sops/age/keys.txt}
k() { kubectl --context "$context" "$@"; }

[[ -f $key ]] || { echo "age key not found: $key" >&2; exit 1; }

if helm status flux-operator --namespace flux-system --kube-context "$context" >/dev/null 2>&1; then
  echo "flux-operator is already installed, Flux manages it now"
else
  helm dependency build "$dir"
  helm install flux-operator "$dir" --namespace flux-system --create-namespace --kube-context "$context"
fi
k -n flux-system rollout status deployment/flux-operator --timeout=5m

k -n flux-system create secret generic sops-age --from-file=age.agekey="$key" --dry-run=client -o yaml | k apply -f - >/dev/null

if k -n flux-system get fluxinstance flux >/dev/null 2>&1; then
  echo "FluxInstance already exists, Flux manages it now"
else
  k apply -f kubernetes/flux/instance/flux-instance.yaml
fi
k -n flux-system wait fluxinstance/flux --for=condition=Ready --timeout=10m
