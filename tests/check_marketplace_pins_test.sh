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

# Remote mode with stub git/curl: a network error must exit 2, not 1, so CI
# can tell "pin is wrong" from "GitHub was unreachable".
# remote_expect <expected-exit> <label> <git-stub-body> <curl-stub-body> [manifest-json]
remote_expect() {
  local want="$1" label="$2" got=0
  mkdir -p "$tmp/bin"
  printf '#!/usr/bin/env bash\n%s\n' "$3" >"$tmp/bin/git"
  printf '#!/usr/bin/env bash\n%s\n' "$4" >"$tmp/bin/curl"
  chmod +x "$tmp/bin/git" "$tmp/bin/curl"
  if [[ -n "${5:-}" ]]; then
    printf '%s\n' "$5" >"$tmp/m.json"
  else
    manifest "$(entry "{\"source\":\"github\",\"repo\":\"o/r\",\"ref\":\"1.0.0\",\"sha\":\"$sha_ok\"}")" >"$tmp/m.json"
  fi
  PATH="$tmp/bin:$PATH" bash "$check" "$tmp/m.json" >"$tmp/out" 2>&1 || got=$?
  if [[ "$got" -eq "$want" ]]; then
    echo "pass: $label (exit $got)"
    pass=$((pass + 1))
  else
    echo "FAIL: $label: expected exit $want, got $got"
    sed 's/^/    /' "$tmp/out"
    failed=$((failed + 1))
  fi
}

sha_other="${sha_ok//0/1}"
tag_line="printf '%s\\trefs/tags/1.0.0\\n' $sha_ok"
# curl stub body: serve <http-code> [body]; write body to the -o file, print the code like -w.
curl_http() {
  # shellcheck disable=SC2016  # the stub body expands at stub run time
  printf 'out=/dev/null; while [[ $# -gt 0 ]]; do [[ $1 == -o ]] && { out=$2; shift; }; shift; done\nprintf %%s %q >"$out"\nprintf %%s %s\n' "${2:-}" "$1"
}
remote_expect 0 "remote: tag and plugin.json match" "$tag_line" "$(curl_http 200 '{"version":"1.0.0"}')"
remote_expect 2 "remote: git ls-remote network error" "exit 128" "exit 0"
remote_expect 1 "remote: tag missing" "exit 0" "exit 0"
remote_expect 1 "remote: tag points elsewhere" "printf '%s\\trefs/tags/1.0.0\\n' $sha_other" "exit 0"
remote_expect 2 "remote: curl network error" "$tag_line" "exit 6"
remote_expect 1 "remote: plugin.json HTTP 404" "$tag_line" "$(curl_http 404)"
remote_expect 2 "remote: plugin.json HTTP 503 is a network error, not a pin failure" "$tag_line" "$(curl_http 503)"
remote_expect 2 "remote: plugin.json HTTP 429 is a network error" "$tag_line" "$(curl_http 429)"
remote_expect 1 "remote: repository not found is a pin failure" \
  "echo 'remote: Repository not found.' >&2; echo \"fatal: repository 'https://github.com/o/r/' not found\" >&2; exit 128" "exit 0"
remote_expect 2 "remote: DNS failure stays a network error" \
  "echo \"fatal: unable to access 'https://github.com/o/r/': Could not resolve host: github.com\" >&2; exit 128" "exit 0"
remote_expect 1 "remote: a pin failure in one entry wins over a network error in another" \
  "[[ \"\$*\" == *o/r2* ]] && exit 128; exit 0" "exit 0" \
  "$(manifest "$(entry "{\"source\":\"github\",\"repo\":\"o/r\",\"ref\":\"1.0.0\",\"sha\":\"$sha_ok\"}"),$(entry "{\"source\":\"github\",\"repo\":\"o/r2\",\"ref\":\"1.0.0\",\"sha\":\"$sha_ok\"}")")"
remote_expect 1 "remote: plugin.json version differs" "$tag_line" "$(curl_http 200 '{"version":"1.0.1"}')"

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
