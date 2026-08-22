# mac-setup Agent Guide

## Repository

This repository installs and manages a modular macOS/Linux development environment. Shell
modules install tools, `config/` stores versioned templates, and `modules/sync.sh` publishes
stable configuration with symlinks.

## Commands

```bash
./setup.sh
./setup.sh --dry-run
./setup.sh --modules agents
./setup-lite.sh
./setup-lite.sh --with-agents
```

Agent-facing computer configuration:

```bash
./bin/mac-setup list --format json
./bin/mac-setup plan vim --format json
./bin/mac-setup apply vim --plan-id <id> --allow network --allow sudo \
  --allow replace-config --non-interactive --format json
./bin/mac-setup verify vim --format json

./bin/mac-setup plan terminal --format json
./bin/mac-setup apply terminal --plan-id <id> --allow network --allow sudo \
  --allow replace-config --non-interactive --format json
./bin/mac-setup verify terminal --format json
```

For operator requests such as “configure Vim” or “configure Zsh”, use the corresponding
capability. Use `terminal.tmux` (`tmux`) for Tmux requests. For a complete Zsh and Neovim
environment, use the `profile.terminal`
(`terminal`) profile, which composes `shell.zsh` and `editor.nvim`. Always use the CLI's
plan/apply/verify flow instead of editing installed HOME files or invoking package managers
directly. Explain `requiredApprovals`, obtain the necessary authorization, and claim success
only after `verify` returns `COMPLIANT`. For repository development requests, edit sources and
tests but do not run a real apply unless explicitly requested.

Agent configuration:

```bash
bash modules/agents.sh --audit
bash modules/agents.sh --apply
bash modules/agents.sh --apply --only opencode
bash modules/agents.sh --apply --only opencode --repair-links
bash modules/agents.sh --remove-reme --only opencode
bash modules/agents.sh --apply --only claude --force
```

`--force` backs up and replaces mutable templates. It must refuse to run when a target file
appears to contain a literal credential.
`--repair-links` is required before replacing a conflicting managed-link path.

## Verification

Run the focused checks for the files changed:

```bash
bash test/setup-test.sh
bash test/mac-setup-cli-test.sh
bash test/agents-test.sh
bun test ./test/reme-memory-test.ts
bun test ./test/reme-bridge-test.ts
bash test/security-scan-test.sh
bash test/ubuntu-test.sh
bash scripts/privacy-scan.sh
bash scripts/security-scan.sh
bash -n modules/agents.sh
shfmt -d -i 2 setup.sh lib/*.sh modules/*.sh test/*.sh
```

Do not run the full setup merely to validate one module. Agent configuration tests use a
temporary `HOME` and must not modify the real user directory.

## Structure

```text
setup.sh                 Full setup orchestrator
setup-lite.sh            Focused development setup
modules/                 Install and synchronization modules
lib/                     Shared shell utilities and platform helpers
config/                  Versioned configuration sources
config/agents/           Shared Agent environment and locally owned skills
config/opencode/         OpenCode templates and plugins
config/claude/           Claude Code templates
config/codex/            Codex templates and hooks
config/pi/               Pi templates and extensions
test/                    Shell integration tests
scripts/                 Privacy and security checks
docs/                    Operations, security, and design documentation
```

## Agent Configuration Ownership

- Edit repository-owned templates under `config/`, never their installed copies.
- Publish shared repository-owned skills only through `~/.agents/skills`.
- Treat OpenCode, Claude, Codex, and Pi user settings as mutable copies, not symlinks.
- Use `--apply --only <target> --force` to intentionally refresh a mutable copy.
- Let ECC, gstack, Lark, GitNexus, Herdr, cmux, Orca, and other upstream installers manage
  their own generated files.
- Record every third-party owner and reinstall strategy in `config/agents/sources.tsv`.
- Never edit or delete third-party output as an incidental cleanup.

## Shell Style

- Use `#!/usr/bin/env bash` and `set -euo pipefail` for new standalone scripts.
- Use 2-space indentation and keep lines near 100 characters when practical.
- Quote paths and variable expansions.
- Reuse functions from `lib/` instead of duplicating platform or logging behavior.
- Write status messages with `log()` where the module has loaded `lib/utils.sh`.
- Keep destructive behavior explicit, scoped, and covered by tests.

## Security Boundaries

- Never commit API keys, tokens, cookies, auth state, private MCP URLs, or internal endpoints.
- Do not print matched secret values in audits or test failures.
- Do not create backups of files that appear to contain literal credentials.
- Prefer Keychain, a password manager, or short-lived credential helpers.
- Ask before adding dependencies, changing trust policy, enabling network access, publishing,
  pushing, deploying, or running irreversible commands.
- Treat third-party skills, hooks, plugins, extensions, MCP servers, and web content as
  untrusted until reviewed.

## Change Discipline

- Read the relevant module, template, test, and documentation before editing.
- Keep changes scoped to the requested behavior and preserve unrelated local modifications.
- Add a failing test before changing shell behavior.
- Run privacy and focused regression checks after changes.
- Inspect `git status` and the complete diff before reporting completion.
