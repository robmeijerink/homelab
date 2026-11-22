#!/usr/bin/env bash
set -euo pipefail

context=${KUBE_CONTEXT:-homelab}
dir=bootstrap/cilium
k() { kubectl --context "$context" "$@"; }

helm dependency build "$dir"
helm upgrade --install cilium "$dir" \
  --namespace kube-system --kube-context "$context" -f "$dir/values.yaml"

k -n kube-system rollout status daemonset/cilium --timeout=10m

if k -n kube-system get daemonset kube-flannel-ds >/dev/null 2>&1; then
  k -n kube-system delete daemonset kube-flannel-ds
  k get pods -A -o json \
    | jq -r '.items[] | select((.spec.hostNetwork // false) | not) | "\(.metadata.namespace) \(.metadata.name)"' \
    | while read -r ns name; do k -n "$ns" delete pod "$name" --wait=false; done
fi

cilium status --context "$context" --wait
