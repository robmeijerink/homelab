#!/usr/bin/env bash
set -euo pipefail

deny_file=${HYGIENE_DENY_FILE:-$HOME/.config/homelab/hygiene-deny}
rc=0

for f in "$@"; do
  [[ -f $f ]] || continue
  [[ $f == *.sops.yaml && ${f##*/} != .sops.yaml ]] && continue
  grep -Iq . "$f" || continue

  awk -v f="$f" '
    function bad(what, v) {
      printf "%s:%d: %s: %s\n", f, NR, what, v
      found = 1
    }
    /hygiene:allow/ { next }
    {
      rest = $0
      while (match(rest, /[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/)) {
        ip = substr(rest, RSTART, RLENGTH)
        rest = substr(rest, RSTART + RLENGTH)
        n = split(ip, o, ".")
        valid = 1
        for (i = 1; i <= n; i++) if (o[i] > 255) valid = 0
        if (valid && ip !~ /^(0\.0\.0\.0|127\.|255\.|169\.254\.|192\.0\.2\.|198\.51\.100\.|203\.0\.113\.)/) bad("IPv4 address", ip)
      }

      rest = $0
      while (match(rest, /[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]+/)) {
        addr = substr(rest, RSTART, RLENGTH)
        rest = substr(rest, RSTART + RLENGTH)
        split(addr, a, "@")
        if (a[1] != "git" && a[2] !~ /^(users\.noreply\.github\.com|example\.(com|org|invalid))$/) bad("email address", addr)
      }

      if (match($0, /ocid1\.[a-z0-9_]+\.oc[0-9]\.[a-z0-9-]*\.[a-z0-9]+/)) {
        id = substr($0, RSTART, RLENGTH)
        n = split(id, p, ".")
        if (length(p[n]) >= 20) bad("OCI identifier", id)
      }

      if (match($0, /[a-z0-9-]+\.ts\.net/)) bad("tailnet name", substr($0, RSTART, RLENGTH))

      lower = tolower($0)
      if (match(lower, /(account|zone|tunnel)[_-]?id[^0-9a-f]+[0-9a-f]+/)) {
        s = substr(lower, RSTART, RLENGTH)
        sub(/.*[^0-9a-f]/, "", s)
        if (length(s) == 32) bad("Cloudflare identifier", s)
      }
    }
    END { exit found }
  ' "$f" || rc=1

  if [[ -f $deny_file ]]; then
    hits=$(grep -nIiE -f "$deny_file" "$f" | grep -v 'hygiene:allow' | cut -d: -f1 || true)
    for n in $hits; do
      echo "$f:$n: matches the private deny list" >&2
      rc=1
    done
  fi
done

exit "$rc"
