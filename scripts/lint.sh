#!/usr/bin/env bash
# Runs SwiftLint and fails when there are more than MAX_VIOLATIONS violations.
# Used as a pre-build phase of the app target (project.yml) and runnable by hand.
set -uo pipefail

MAX_VIOLATIONS="${MAX_VIOLATIONS:-3}"
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v swiftlint >/dev/null 2>&1; then
  echo "warning: SwiftLint is not installed (brew install swiftlint). Lint skipped."
  exit 0
fi

cd "$ROOT"
OUTPUT="$(swiftlint lint --quiet --reporter xcode 2>/dev/null)"
if [ -n "$OUTPUT" ]; then
  echo "$OUTPUT"
fi
COUNT=$(printf '%s\n' "$OUTPUT" | grep -cE ': (warning|error): ' || true)

if [ "$COUNT" -gt "$MAX_VIOLATIONS" ]; then
  echo "error: SwiftLint found $COUNT violations (limit: $MAX_VIOLATIONS). Fix them to build."
  exit 1
fi
echo "SwiftLint: $COUNT violation(s), limit $MAX_VIOLATIONS."
