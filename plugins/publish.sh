#!/usr/bin/env bash
# Publish the exact distribution tree that the build job validated.
set -euo pipefail

dist=$(cd "$1" && pwd)
version=$2
source_commit=$3
branch_ref=refs/heads/plugin-dist
tag_ref="refs/tags/plugin-v$version"
git_dir=$(git rev-parse --absolute-git-dir)

if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Invalid distribution version: $version" >&2
  exit 1
fi

index_dir=$(mktemp -d)
export GIT_INDEX_FILE="$index_dir/index"
trap 'rm -f "$GIT_INDEX_FILE"; rmdir "$index_dir"' EXIT
git -C "$dist" --git-dir="$git_dir" --work-tree="$dist" add --force --all -- .
tree=$(git write-tree)

# Reruns can reuse a published version only when its tree is identical.
if [[ -n "$(git ls-remote --refs origin "$tag_ref")" ]]; then
  git fetch --no-tags origin "$tag_ref"
  if [[ "$(git rev-parse 'FETCH_HEAD^{tree}')" == "$tree" ]]; then
    echo "plugin-v$version is already published"
    exit 0
  fi
  echo "plugin-v$version already points to a different tree" >&2
  exit 1
fi

parent=()
if [[ -n "$(git ls-remote --refs origin "$branch_ref")" ]]; then
  git fetch --no-tags origin "$branch_ref"
  parent=(-p "$(git rev-parse FETCH_HEAD)")
fi

current_main=$(git ls-remote origin refs/heads/main | cut -f1)
if [[ "$current_main" != "$source_commit" ]]; then
  echo "Skipping publication for superseded main commit $source_commit"
  exit 0
fi

commit=$(git -c user.name='github-actions[bot]' -c user.email='41898282+github-actions[bot]@users.noreply.github.com' \
  commit-tree "$tree" "${parent[@]}" -m "Build Agent Tools plugins $version" -m "Source: $source_commit")
git push --atomic origin "$commit:$branch_ref" "$commit:$tag_ref"
