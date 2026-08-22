---
name: mac-setup
description: Configure or verify this computer's Vim, Neovim, and Zsh environment through the mac-setup repository's safe plan/apply/verify interface.
---

# mac-setup operator

Use this skill when the user asks to configure, install, repair, inspect, or verify a local
development environment managed by mac-setup. Common triggers include Vim, Neovim, Nvim,
Zsh, shell configuration, or setting up a new computer.

## Operator mode

When the user wants this computer configured, use the stable `mac-setup` CLI. Do not edit
installed files such as `~/.zshrc` or `~/.config/nvim` directly, and do not bypass the CLI
with raw `brew`, `apt`, `curl | sh`, or ad-hoc symlink commands.

1. Locate the CLI with `command -v mac-setup`. If unavailable and the current repository is
   mac-setup, use `./bin/mac-setup`.
2. Discover capabilities with `mac-setup list --format json` when the requested target is
   unclear.
3. Run `mac-setup doctor --format json` and then `mac-setup plan <capability> --format json`.
4. Explain the plan, including every item in `requiredApprovals`. Do not claim that dry-run
   output means the environment is configured.
5. Obtain user approval before network access, sudo, changing the login shell, or any other
   approval listed by the plan. Existing Vim/Zsh configuration may be replaced when the user
   has asked mac-setup to configure a fresh computer, but still report that planned change.
6. Apply the reviewed plan with its exact ID, explicit `--allow` flags, `--non-interactive`,
   and `--format json`.
7. Always run `mac-setup verify <capability> --format json` after apply. Report success only
   when the result is `COMPLIANT`.
8. If the CLI returns `BLOCKED`, `FAILED`, or `DRIFT`, report its structured error/checks and
   the safest next action. Never silently work around the boundary.

Canonical capability mappings:

- Vim, Nvim, Neovim, editor environment: `editor.nvim` (aliases: `vim`, `nvim`, `neovim`)
- Zsh or shell environment: `shell.zsh` (aliases: `zsh`, `shell`)

Example flow:

```bash
mac-setup plan vim --format json
mac-setup apply vim --plan-id PLAN_ID --allow network --allow sudo \
  --allow replace-config --non-interactive --format json
mac-setup verify vim --format json
```

Use `--with python-provider` consistently on plan, apply, and verify when the user wants
Neovim's Python provider (`pynvim` and `neovim-remote`).

## Developer mode

When the user asks to change the mac-setup repository itself, edit repository-owned sources
and tests instead of operating on installed copies. Add a failing test before changing shell
behavior, run focused tests in a temporary HOME, run privacy checks, and do not perform a real
apply, install dependencies, push, or publish unless the user explicitly requests it.
