#!/usr/bin/env bash
# Synced from plugins/zvec-grep.version in the source repository.
ZG_PACKAGE="@zvec/zvec-grep@0.3.1"
ZG_ALLOW_SCRIPTS="--allow-scripts=@zvec/zvec-grep"

zg_has_pinned_version() {
  local version
  version=$(zg --version 2>/dev/null) && [[ "$version" == "${ZG_PACKAGE##*@}" ]]
}

zg_run() {
  if zg_has_pinned_version; then
    zg "$@"
  elif command -v npx >/dev/null 2>&1; then
    npx --yes "$ZG_ALLOW_SCRIPTS" "$ZG_PACKAGE" "$@"
  else
    printf 'Install Node.js with npx or put zg %s on PATH.\n' "${ZG_PACKAGE##*@}" >&2
    return 1
  fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  zg_run "$@"
fi
