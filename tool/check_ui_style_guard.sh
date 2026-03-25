#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

echo "Checking UI style guard rules..."

PATTERNS=(
  "\\bColors\\."
  "Color\\(0x"
  "TextStyle\\("
)

EXCLUDE_GLOBS=(
  "!lib/ui/theme/**"
  "!lib/ui/**/**painter.dart"
  "!lib/ui/map/layers/**"
)

has_violations=0
glob_args=()
for glob in "${EXCLUDE_GLOBS[@]}"; do
  glob_args+=(--glob "${glob}")
done

for pattern in "${PATTERNS[@]}"; do
  if rg -n "${pattern}" lib/ui "${glob_args[@]}"; then
    has_violations=1
  fi
done

if [[ "${has_violations}" -eq 1 ]]; then
  cat <<'EOF'
UI style guard failed.

Disallowed in lib/ui (outside approved exclusions):
- Colors.*
- Color(0x...)
- TextStyle(...)

Use ThemeData / ColorScheme / TextTheme and design system widgets/tokens instead.
EOF
  exit 1
fi

echo "UI style guard passed."
