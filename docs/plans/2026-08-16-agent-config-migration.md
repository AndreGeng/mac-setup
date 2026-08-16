# Agent Configuration Migration

## Objective

Restore the stable configuration for OpenCode, Claude Code, Codex, Pi, and locally authored
shared skills on a new machine without committing credentials, auth state, sessions, caches,
or third-party installations.

## Ownership Model

- **Templates:** mutable application settings are copied only when absent. Set
  `MAC_SETUP_FORCE_AGENT_CONFIG=1` to replace them after creating timestamped backups.
- **Managed links:** locally authored plugins and skills are symlinked from this repository.
- **Upstream installs:** ECC, gstack, Lark, GitNexus, Herdr, cmux, Orca, and application
  runtimes are reconstructed from the documented source manifest instead of vendored.
- **Secrets:** only variable names are committed. Values remain in shell-local configuration
  or a password manager.

## Installed Surfaces

- OpenCode: main config, global instructions, TUI/DCP settings, Context7 rule, Workmux plugin.
- Claude Code: global instructions and a sanitized settings template.
- Codex: stable preferences and portable hooks, excluding project trust and generated state.
- Pi: stable preferences, optional environment-rendered provider models, Workmux extension.
- Shared skills: `dispatch` and `dispatch-team`, linked to shared/Codex/Pi skill roots.

## Commands

- Install: `bash modules/agents.sh`
- Force template refresh: `MAC_SETUP_FORCE_AGENT_CONFIG=1 bash modules/agents.sh`
- Verify: `./test/agents-test.sh`
- Security: `./scripts/security-scan.sh`

## Boundaries

- Never copy `auth.json`, settings backups, histories, sessions, transcripts, SQLite files,
  generated plugin caches, or model catalogs.
- Never embed personal absolute paths, internal endpoints, tokens, or enterprise email data.
- Never recursively copy an agent home directory.

## Success Criteria

- A temporary HOME receives all expected templates and links.
- Existing mutable settings survive a normal rerun.
- Force mode backs up and refreshes mutable settings.
- No committed file triggers the repository security scanner.
