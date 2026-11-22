#!/usr/bin/env bash
set -euo pipefail

crd_schemas='https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json'
cache_dir=${XDG_CACHE_HOME:-$HOME/.cache}/kubeconform
mkdir -p "$cache_dir"

rc=0
while IFS= read -r -d '' file; do
  dir=$(dirname "$file")
  echo "validate $dir"
  if ! kustomize build "$dir" \
    | yq 'del(.sops)' \
    | kubeconform -strict -summary -cache "$cache_dir" \
        -schema-location default -schema-location "$crd_schemas" -; then
    echo "FAILED: $dir" >&2
    rc=1
  fi
done < <(find kubernetes -name kustomization.yaml -print0 | sort -z)

if [[ -n $(find kubernetes/flux -name '*.yaml' -print -quit 2>/dev/null) ]]; then
  flate test --path kubernetes/flux || rc=1
fi

for chart in bootstrap/*/Chart.yaml; do
  [[ -f $chart ]] || continue
  dir=$(dirname "$chart")
  echo "validate $dir"
  helm dependency build "$dir" >/dev/null || rc=1
  if ! helm template "$dir" --namespace kube-system \
    | kubeconform -strict -summary -skip CustomResourceDefinition -cache "$cache_dir" \
        -schema-location default -schema-location "$crd_schemas" -; then
    echo "FAILED: $dir" >&2
    rc=1
  fi
done

for dir in infra/*/; do
  [[ -f ${dir}main.tf ]] || continue
  echo "validate $dir"
  tofu -chdir="$dir" init -backend=false -input=false >/dev/null || rc=1
  tofu -chdir="$dir" validate || rc=1
done

exit "$rc"
