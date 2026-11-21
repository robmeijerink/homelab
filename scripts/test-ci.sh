#!/usr/bin/env bash
set -eEuo pipefail
trap 'echo "test-ci: failed at line $LINENO" >&2' ERR

repo=robmeijerink/homelab
timeout_s=600

fixture() {
  case $1 in
    t1_1)
      mkdir -p kubernetes/apps/test
      cat >kubernetes/apps/test/kustomization.yaml <<'YAML'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - deployment.yaml
YAML
      cat >kubernetes/apps/test/deployment.yaml <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: invalid
spec:
  replicas: three
YAML
      ;;
    t1_2)
      mkdir -p kubernetes/apps/test
      cat >kubernetes/apps/test/secret.yaml <<'YAML'
apiVersion: v1
kind: Secret
metadata:
  name: plaintext
stringData:
  key: not-a-real-value
YAML
      ;;
    t1_3)
      mkdir -p .github/workflows
      cat >.github/workflows/unpinned.yaml <<'YAML'
name: unpinned
on: workflow_dispatch
permissions: {}
jobs:
  test:
    runs-on: ubuntu-24.04
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@v4
YAML
      ;;
  esac
}

git fetch -q origin main
git worktree prune
while read -r stale; do
  git worktree remove --force "$stale"
done < <(git worktree list --porcelain | awk '/^worktree /{p=$2} /^branch refs\/heads\/test\//{print p}')
tmp=$(mktemp -d)
git worktree add -q --detach "$tmp/wt" origin/main
cd "$tmp/wt"

branch=""
pr=""
# shellcheck disable=SC2329
cleanup() {
  if [[ -n $pr ]]; then
    gh pr close "$pr" --repo "$repo" >/dev/null 2>&1 || true
  fi
  if [[ -n $branch ]]; then
    gh api -X DELETE "repos/$repo/git/refs/heads/$branch" >/dev/null 2>&1 || true
  fi
  cd - >/dev/null
  git worktree remove --force "$tmp/wt"
  rm -rf "$tmp"
}
trap cleanup EXIT

results=()
rc=0

run_case() {
  local id=$1 check=$2 reason=$3
  branch="test/$id"

  echo "== $id: expecting $check to fail"
  gh pr close "$branch" --repo "$repo" >/dev/null 2>&1 || true
  gh api -X DELETE "repos/$repo/git/refs/heads/$branch" >/dev/null 2>&1 || true
  git branch -D "$branch" >/dev/null 2>&1 || true

  git switch -q -c "$branch"
  fixture "$id"
  git add -A
  git -c core.hooksPath=/dev/null commit -q -m "test: $id"
  git push -q origin "$branch"
  local url
  url=$(gh pr create --repo "$repo" --base main --head "$branch" \
    --title "test: $id" --body "Automated check of the required CI jobs. Closed unmerged.")
  pr=${url##*/}
  echo "   PR #$pr, waiting for $check"

  local waited=0 conclusion=""
  while ((waited < timeout_s)); do
    conclusion=$(gh pr view "$pr" --repo "$repo" --json statusCheckRollup \
      --jq "(.statusCheckRollup // [])[] | select(.name == \"$check\") | .conclusion" | head -n1 || true)
    [[ -n $conclusion ]] && break
    sleep 15
    waited=$((waited + 15))
  done

  local msg run_id
  if [[ $conclusion == FAILURE ]]; then
    run_id=$(gh run list --repo "$repo" --branch "$branch" --workflow "$check" --limit 1 \
      --json databaseId --jq '.[0].databaseId')
    if gh run view "$run_id" --repo "$repo" --log-failed | grep -qF "$reason"; then
      msg="$id: $check failed as expected"
    else
      msg="$id: $check failed, but not with '$reason'"
      rc=1
    fi
  else
    msg="$id: expected $check to fail, got '${conclusion:-no result}'"
    rc=1
  fi
  results+=("$msg")
  echo "   $msg"

  gh pr close "$pr" --repo "$repo" >/dev/null
  gh api -X DELETE "repos/$repo/git/refs/heads/$branch" >/dev/null
  pr=""
  branch=""
  git switch -q --detach origin/main
  git branch -D "test/$id" >/dev/null
  git clean -fdq
}

run_case t1_1 validate "is invalid"
run_case t1_2 secrets "kind: Secret outside a *.sops.yaml file"
run_case t1_3 lint "unpinned-uses"

if gh issue list --repo "$repo" --search "Dependency Dashboard" --json title --jq '.[].title' | grep -q .; then
  results+=("t1_5: dependency dashboard issue exists")
else
  results+=("t1_5: no dependency dashboard issue found")
  rc=1
fi

printf '%s\n' "${results[@]}"
exit "$rc"
