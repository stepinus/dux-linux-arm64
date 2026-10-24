#!/usr/bin/env bash
# Resolve the upstream release tag for every Dux component and emit a build matrix
# (plus the suite version) as GitHub Actions step outputs.
set -euo pipefail

ref_override=${REF:-}
repos="dux-shell dux-greeter dux-search dux-calendar dux-files dux-gop"

entries=()
versions=()
for repo in $repos; do
  if [ -n "$ref_override" ]; then
    ref=$ref_override
  else
    ref=$(gh api "repos/duxlabs-dev/$repo/releases/latest" --jq .tag_name)
  fi
  case $repo in
    dux-shell | dux-greeter | dux-calendar | dux-files) gomod=core/go.mod ;;
    *) gomod=go.mod ;;
  esac
  versions+=("${ref#v}")
  entries+=("{\"pkg\":\"$repo\",\"repo\":\"$repo\",\"ref\":\"$ref\",\"gomod\":\"src/$gomod\"}")
done

if [ "$(printf '%s\n' "${versions[@]}" | sort -u | wc -l)" -eq 1 ]; then
  version=${versions[0]}
else
  version="suite-$(date -u +%Y%m%d)"
fi

echo "matrix={\"include\":[$(printf '%s' "${entries[0]}"; printf ',%s' "${entries[@]:1}")]}"
echo "version=$version"
