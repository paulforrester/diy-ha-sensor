#!/usr/bin/env bash
# Build throwaway secrets for CI (or a local test build) from secrets.example.yaml: every API-key placeholder gets
# a fresh random key. Writes firmware/secrets.yaml and firmware/ci/secrets.yaml, both git-ignored.
# Refuses to overwrite an existing firmware/secrets.yaml, which may hold real credentials.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
fw="$(dirname "$here")"
if [ -e "$fw/secrets.yaml" ] && [ "${1:-}" != "--force" ]; then
  echo "firmware/secrets.yaml exists; not overwriting (pass --force in CI only)" >&2
  exit 1
fi
key="$(openssl rand -base64 32)"
sed "s|REPLACE-WITH-openssl-rand-base64-32|${key}|g" "$fw/secrets.example.yaml" > "$fw/secrets.yaml"
cp "$fw/secrets.yaml" "$here/secrets.yaml"
echo "wrote firmware/secrets.yaml and firmware/ci/secrets.yaml with throwaway keys"
