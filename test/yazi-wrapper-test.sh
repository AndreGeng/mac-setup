#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEMP_ROOT"' EXIT
sed -n '/^y() {$/,/^}/p' "$ROOT_DIR/config/.zshrc" >"$TEMP_ROOT/wrapper.zsh"
cat >"$TEMP_ROOT/yazi" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$FZF_DEFAULT_COMMAND" >"$TRACE"
EOF
chmod +x "$TEMP_ROOT/yazi"
PATH="$TEMP_ROOT:$PATH" TRACE="$TEMP_ROOT/trace" zsh -f -c '
  source "$1"
  export FZF_DEFAULT_COMMAND="original-command"
  y
  [[ "$FZF_DEFAULT_COMMAND" == original-command ]]
' fixture "$TEMP_ROOT/wrapper.zsh"
grep -Fxq 'fd --hidden --type f --exclude .git' "$TEMP_ROOT/trace"
printf 'PASS Yazi includes hidden files without changing the shell environment\n'
