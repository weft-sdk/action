#!/usr/bin/env bash
# Runs the checks the inputs ask for, writes a summary, and fails if any of them failed.
set -uo pipefail

failed=0
summary="${GITHUB_STEP_SUMMARY:-/dev/null}"
details="$(mktemp)"
{
  echo "## Weft"
  echo
} >> "$summary"

row() { echo "| $1 | $2 |" >> "$summary"; }
{
  echo "| Check | Result |"
  echo "| --- | --- |"
} >> "$summary"

if [ "${INPUT_CHECK:-true}" = "true" ]; then
  args=(check --json)
  if [ -n "${INPUT_BASELINE:-}" ]; then args+=(--baseline "$INPUT_BASELINE"); fi
  json="$(weft "${args[@]}" 2>check.err)"
  code=$?
  if [ $code -eq 0 ]; then
    row "Breaking changes (\`weft check\`)" "✅ passed"
  elif [ $code -eq 1 ]; then
    row "Breaking changes (\`weft check\`)" "❌ breaking changes the version does not cover"
    failed=1
    echo "::error title=Weft contracts::weft check found breaking changes the version does not cover"
    if command -v jq >/dev/null 2>&1; then
      echo "$json" | jq -r '.packages[] | .package as $p | .changes[] | select(.severity=="breaking") | "::error title=Breaking change in \($p)::\(.location): \(.message)"'
      {
        echo
        echo "### Breaking changes"
        echo
        echo "| Package | Where | What |"
        echo "| --- | --- | --- |"
        echo "$json" | jq -r '.packages[] | .package as $p | .changes[] | select(.severity=="breaking") | "| \($p) | `\(.location)` | \(.message) |"'
      } >> "$details"
    fi
  elif grep -q "no baseline" check.err 2>/dev/null; then
    row "Breaking changes (\`weft check\`)" "⏭ skipped: no git tag to compare with"
    echo "::notice title=Weft::weft check was skipped because the repository has no release tag. Tag a release, or pass the baseline input. Use actions/checkout with fetch-depth: 0 so tags are available."
  else
    row "Breaking changes (\`weft check\`)" "❌ could not run"
    failed=1
    cat check.err >&2
  fi
  rm -f check.err
fi

if [ "${INPUT_GEN_CHECK:-true}" = "true" ]; then
  if out="$(weft gen --check 2>&1)"; then
    row "Generated code (\`weft gen --check\`)" "✅ up to date"
  else
    row "Generated code (\`weft gen --check\`)" "❌ out of date: run \`weft gen\`"
    failed=1
    echo "::error title=Weft generated code::$out"
  fi
fi

if [ "${INPUT_FMT_CHECK:-true}" = "true" ]; then
  if out="$(weft fmt --check 2>&1)"; then
    row "Formatting (\`weft fmt --check\`)" "✅ formatted"
  else
    row "Formatting (\`weft fmt --check\`)" "❌ not formatted: run \`weft fmt\`"
    failed=1
    echo "::error title=Weft formatting::$out"
  fi
fi

cat "$details" >> "$summary"
rm -f "$details"

if [ $failed -eq 0 ]; then
  echo "passes=true" >> "${GITHUB_OUTPUT:-/dev/null}"
else
  echo "passes=false" >> "${GITHUB_OUTPUT:-/dev/null}"
fi
exit $failed
