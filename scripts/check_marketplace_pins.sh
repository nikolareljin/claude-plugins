#!/usr/bin/env bash
# Check that every github plugin entry in marketplace.json is pinned to a release.
#
# Offline checks (always run):
#   - source.ref is a non-empty tag name
#   - source.sha is a 40-character lowercase hex commit id
# Remote checks (skipped with --offline):
#   - the tag exists in the plugin repository and resolves to source.sha
#     (an annotated tag is peeled to the commit it points at)
#   - .claude-plugin/plugin.json at that tag has version == source.ref
#
# Usage: scripts/check_marketplace_pins.sh [--offline] [path/to/marketplace.json]
# Exit code: 0 when every entry passes, 1 on any failure, 2 on usage or tooling errors.
set -euo pipefail

offline=0
manifest=""
for arg in "$@"; do
  case "$arg" in
    --offline) offline=1 ;;
    -h|--help) sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*) echo "unknown option: $arg" >&2; exit 2 ;;
    *) manifest="$arg" ;;
  esac
done

if [[ -z "$manifest" ]]; then
  repo_root="$(cd "$(dirname "$0")/.." && pwd)"
  manifest="$repo_root/.claude-plugin/marketplace.json"
fi

for tool in jq git curl; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "missing tool: $tool" >&2
    exit 2
  fi
done

if [[ ! -f "$manifest" ]]; then
  echo "manifest not found: $manifest" >&2
  exit 2
fi

if ! jq -e . "$manifest" >/dev/null 2>&1; then
  echo "FAIL: $manifest is not valid JSON" >&2
  exit 1
fi

failures=0
fail() {
  echo "FAIL: $*" >&2
  failures=$((failures + 1))
}

count="$(jq -r '.plugins | length' "$manifest")"
if [[ "$count" -eq 0 ]]; then
  fail "no plugin entries"
fi

for ((i = 0; i < count; i++)); do
  name="$(jq -r ".plugins[$i].name // \"plugins[$i]\"" "$manifest")"
  # A relative-path source is a string, not an object; report it as unpinned instead of erroring in jq.
  type="$(jq -r ".plugins[$i].source | if type == \"object\" then (.source // \"\") else \"\" end" "$manifest")"
  if [[ "$type" != "github" ]]; then
    fail "$name: source.source is '$type', expected 'github'"
    continue
  fi
  repo="$(jq -r ".plugins[$i].source.repo // \"\"" "$manifest")"
  ref="$(jq -r ".plugins[$i].source.ref // \"\"" "$manifest")"
  sha="$(jq -r ".plugins[$i].source.sha // \"\"" "$manifest")"

  if [[ ! "$repo" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]]; then
    fail "$name: source.repo '$repo' is not owner/repo"
    continue
  fi
  if [[ -z "$ref" ]]; then
    fail "$name: source.ref missing"
  fi
  if [[ ! "$sha" =~ ^[0-9a-f]{40}$ ]]; then
    fail "$name: source.sha '$sha' is not a 40-character lowercase hex commit id"
  fi
  if [[ -z "$ref" || ! "$sha" =~ ^[0-9a-f]{40}$ ]]; then
    continue
  fi
  if [[ "$offline" -eq 1 ]]; then
    echo "ok (offline): $name $ref $sha"
    continue
  fi

  url="https://github.com/$repo"
  if ! refs="$(git ls-remote "$url" "refs/tags/$ref" "refs/tags/$ref^{}" 2>/dev/null)"; then
    fail "$name: git ls-remote $url failed"
    continue
  fi
  if [[ -z "$refs" ]]; then
    fail "$name: tag '$ref' not found in $url"
    continue
  fi
  # Prefer the peeled commit (annotated tag); fall back to the tag ref itself (lightweight tag).
  tag_commit="$(awk -v r="refs/tags/$ref^{}" '$2 == r { print $1 }' <<<"$refs")"
  if [[ -z "$tag_commit" ]]; then
    tag_commit="$(awk -v r="refs/tags/$ref" '$2 == r { print $1 }' <<<"$refs")"
  fi
  if [[ "$tag_commit" != "$sha" ]]; then
    fail "$name: tag '$ref' resolves to $tag_commit, manifest sha is $sha"
    continue
  fi

  raw="https://raw.githubusercontent.com/$repo/$sha/.claude-plugin/plugin.json"
  if ! plugin_json="$(curl -fsSL "$raw" 2>/dev/null)"; then
    fail "$name: cannot fetch $raw"
    continue
  fi
  plugin_version="$(jq -r '.version // ""' <<<"$plugin_json" 2>/dev/null || true)"
  if [[ "$plugin_version" != "$ref" ]]; then
    fail "$name: plugin.json version '$plugin_version' at $sha does not match ref '$ref'"
    continue
  fi
  echo "ok: $name $ref $sha (plugin.json version $plugin_version)"
done

if [[ "$failures" -gt 0 ]]; then
  echo "$failures failure(s) in $manifest" >&2
  exit 1
fi
echo "all $count plugin entries pinned"
