#!/usr/bin/env bash
# Offline tests for scripts/check_marketplace_pins.sh using fixture manifests.
# Usage: bash tests/check_marketplace_pins_test.sh
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
check="$repo_root/scripts/check_marketplace_pins.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

pass=0
failed=0

# expect <expected-exit> <label> <manifest-json>
expect() {
  local want="$1" label="$2" json="$3" got=0
  printf '%s\n' "$json" >"$tmp/m.json"
  bash "$check" --offline "$tmp/m.json" >"$tmp/out" 2>&1 || got=$?
  if [[ "$got" -eq "$want" ]]; then
    echo "pass: $label (exit $got)"
    pass=$((pass + 1))
  else
    echo "FAIL: $label: expected exit $want, got $got"
    sed 's/^/    /' "$tmp/out"
    failed=$((failed + 1))
  fi
}

sha_ok="0123456789abcdef0123456789abcdef01234567"

entry() {
  # entry <source-json>
  printf '{"name":"p","source":%s}' "$1"
}
manifest() {
  printf '{"name":"m","owner":{"name":"o"},"plugins":[%s]}' "$1"
}

expect 0 "ref and 40-hex sha" \
  "$(manifest "$(entry "{\"source\":\"github\",\"repo\":\"o/r\",\"ref\":\"1.0.0\",\"sha\":\"$sha_ok\"}")")"

expect 1 "missing ref and sha (the unpinned shape this repo had before)" \
  "$(manifest "$(entry '{"source":"github","repo":"o/r"}')")"

expect 1 "missing sha" \
  "$(manifest "$(entry '{"source":"github","repo":"o/r","ref":"1.0.0"}')")"

expect 1 "missing ref" \
  "$(manifest "$(entry "{\"source\":\"github\",\"repo\":\"o/r\",\"sha\":\"$sha_ok\"}")")"

expect 1 "short sha" \
  "$(manifest "$(entry '{"source":"github","repo":"o/r","ref":"1.0.0","sha":"0123456"}')")"

expect 1 "uppercase sha" \
  "$(manifest "$(entry "{\"source\":\"github\",\"repo\":\"o/r\",\"ref\":\"1.0.0\",\"sha\":\"${sha_ok^^}\"}")")"

expect 1 "sha with non-hex character" \
  "$(manifest "$(entry '{"source":"github","repo":"o/r","ref":"1.0.0","sha":"g123456789abcdef0123456789abcdef01234567"}')")"

expect 1 "non-github source" \
  "$(manifest "$(entry '{"source":"url","url":"https://example.com/r.git","ref":"1.0.0","sha":"'"$sha_ok"'"}')")"

expect 1 "relative path source" \
  "$(manifest '{"name":"p","source":"./plugins/p"}')"

expect 1 "empty plugins array" \
  "$(manifest '')"

expect 1 "plugins is not an array" '{"name":"m","owner":{"name":"o"},"plugins":"nope"}'

expect 1 "plugins key missing" '{"name":"m","owner":{"name":"o"}}'

expect 1 "one good entry, one bad entry" \
  "$(manifest "$(entry "{\"source\":\"github\",\"repo\":\"o/r\",\"ref\":\"1.0.0\",\"sha\":\"$sha_ok\"}"),$(entry '{"source":"github","repo":"o/r2"}')")"

expect 1 "invalid JSON" '{"name": "m", "plugins": ['

# The committed manifest must pass the offline check.
got=0
bash "$check" --offline "$repo_root/.claude-plugin/marketplace.json" >"$tmp/out" 2>&1 || got=$?
if [[ "$got" -eq 0 ]]; then
  echo "pass: committed manifest (exit 0)"
  pass=$((pass + 1))
else
  echo "FAIL: committed manifest: exit $got"
  sed 's/^/    /' "$tmp/out"
  failed=$((failed + 1))
fi

echo "$pass passed, $failed failed"
[[ "$failed" -eq 0 ]]
