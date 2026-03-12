#!/bin/bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
TARGET="${SCRIPT_DIR}/claude-model.sh"

assert_hex() {
  local name="$1"
  local input="$2"
  local expected="$3"
  local actual

  actual=$(printf '%s' "$input" | "$TARGET" --model-short --color | xxd -p -c 256)

  if [[ "$actual" != "$expected" ]]; then
    printf 'FAIL %s\nexpected: %s\nactual:   %s\n' "$name" "$expected" "$actual" >&2
    exit 1
  fi
}

assert_hex \
  "opus short badge colors" \
  '{"model":{"id":"claude-opus"}}' \
  "1b5b33383b323b3235353b3235353b3235356d4f501b5b306d"

assert_hex \
  "sonnet short badge colors" \
  '{"model":{"id":"claude-sonnet"}}' \
  "1b5b34383b323b3130383b3231353b3230326d1b5b33383b323b33303b33303b34366d534e1b5b306d"

assert_hex \
  "haiku short badge colors" \
  '{"model":{"id":"claude-haiku"}}' \
  "1b5b34383b323b3235353b3139383b316d1b5b33383b323b3139343b34393b34306d484b1b5b306d"

printf 'PASS claude-model short badge colors\n'
