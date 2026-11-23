#!/usr/bin/env bash
set -euo pipefail

context=${KUBE_CONTEXT:-homelab}
dir=bootstrap/cilium
k() { kubectl --context "$context" "$@"; }

unmanaged() {
  comm -23 \
    <(k get pods -A -o json | jq -r '.items[]
        | select(.status.phase == "Running")
        | select((.spec.hostNetwork // false) | not)
        | "\(.metadata.namespace)/\(.metadata.name)"' | sort) \
    <(k get ciliumendpoints -A -o json | jq -r '.items[] | "\(.metadata.namespace)/\(.metadata.name)"' | sort)
}

helm dependency build "$dir"
helm upgrade --install cilium "$dir" --namespace kube-system --kube-context "$context" --reset-values
k -n kube-system rollout status daemonset/cilium --timeout=10m

cluster_id=$(tofu -chdir=infra/oci-free output -raw cluster_id)
cluster_type=$(oci ce cluster get --cluster-id "$cluster_id" --query 'data.type' --raw-output)
if [[ $cluster_type == ENHANCED_CLUSTER ]]; then
  flannel=$(oci ce cluster list-addons --cluster-id "$cluster_id" \
    --query "length(data[?name=='Flannel'])" --raw-output)
  if [[ $flannel != 0 ]]; then
    oci ce cluster disable-addon --cluster-id "$cluster_id" --addon-name Flannel \
      --is-remove-existing-add-on true --force --wait-for-state SUCCEEDED
  fi
fi
k -n kube-system delete daemonset kube-flannel-ds --ignore-not-found

if k get storageclass oci-bv >/dev/null 2>&1; then
  k annotate storageclass oci-bv storageclass.kubernetes.io/is-default-class=false --overwrite
fi

for pod in $(unmanaged); do
  k -n "${pod%%/*}" delete pod "${pod#*/}" --ignore-not-found --wait=false
done

cilium status --context "$context" --wait
k wait pods -A --field-selector=status.phase=Running --for=condition=Ready --timeout=5m

left=$(unmanaged)
if [[ -n $left ]]; then
  echo "pods not managed by Cilium:" >&2
  echo "$left" >&2
  exit 1
fi
