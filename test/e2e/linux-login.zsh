#!/usr/bin/env zsh
emulate -L zsh
setopt err_return pipe_fail

expected_shell="$(command -v zsh)"
[[ -n "$expected_shell" && "$SHELL" == "$expected_shell" ]] || {
  print -u2 "login shell mismatch: SHELL=${SHELL:-unset}, expected=$expected_shell"
  return 1
}

required_commands="${1:?required command list is missing}"

local command_path command_name
for command_name in ${=required_commands}; do
  command_path="$(command -v "$command_name" 2>/dev/null)" || {
    print -u2 "required command is unavailable in login Zsh: $command_name"
    return 1
  }
  print -r -- "$command_name=$command_path"
done

for command_name in nvim tree-sitter go gopls node bun opencode codex; do
  command_path="$(command -v "$command_name")"
  [[ "$command_path" == "$HOME/.local/bin/$command_name" ]] || {
    print -u2 \
      "managed command bypasses ~/.local/bin in login Zsh: $command_name=$command_path"
    return 1
  }
done

print -r -- 'LOGIN_ZSH_OK'
