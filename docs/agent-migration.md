# Agent Configuration Management

The `agents` module manages stable configuration for OpenCode, Claude Code, Codex, Pi, and
locally maintained shared skills.

## Ownership Model

| Content | Source of truth | Installed form |
|---|---|---|
| Mutable tool settings | `config/<tool>/` | Owner-only copy in the tool home |
| Repository-owned plugins/extensions | `config/<tool>/` | Symlink |
| Repository-owned shared skills | `config/agents/skills/` | Symlink under `~/.agents/skills` |
| Third-party skills/hooks/plugins | Upstream installer | Upstream-owned output |
| Secrets and private endpoints | Keychain/password manager/local secret file | Runtime injection only |

OpenCode, Codex, and Pi discover the shared `~/.agents/skills` directory. Do not create extra
copies under `~/.config/opencode/skills`, `~/.codex/skills`, or `~/.pi/agent/skills` for
repository-owned shared skills. Claude-specific skills remain under `~/.claude/skills` and are
managed by their declared owner.

## Audit

Audit is read-only and returns non-zero when required configuration, managed links, safe file
permissions, JSON validity, or literal-secret checks fail:

```bash
bash modules/agents.sh --audit
bash modules/agents.sh --audit --only opencode
```

Audit output contains rule names and paths only. It never prints matched credential values.
Template differences are warnings because tool settings are mutable local copies.

JSON/JSONC audit and forced replacement require `jq`. Codex TOML audit and forced replacement
require Python 3.11+ with `tomllib`, or Python 3 with the `tomli` package. Missing parsers or
invalid structured configuration fail closed rather than allowing a backup.

Supported targets:

```text
shared  opencode  claude  codex  pi
```

## Apply

Install missing mutable templates and repair repository-managed links:

```bash
bash modules/agents.sh --apply
bash modules/agents.sh --apply --only pi
```

No arguments remains an alias for `--apply` for setup compatibility.

Existing mutable settings are preserved. To intentionally refresh one tool from the repository
template, use a scoped force operation:

```bash
bash modules/agents.sh --apply --only opencode --force
```

Force creates a timestamped backup before replacement. If the current target appears to contain
a literal credential, the entire apply operation stops before modifying any file or creating a
backup. Migrate and revoke the credential first.

Conflicting managed-link paths are never replaced implicitly. Inspect the reported owner and
contents, then opt in to a timestamped backup and link repair:

```bash
bash modules/agents.sh --apply --only opencode --repair-links
```

`--repair-links` does not force replacement of mutable tool settings. Link replacement uses a
unique backup name and restores the original path if link creation fails.

The legacy environment variable remains supported, but the explicit flag is preferred:

```bash
MAC_SETUP_FORCE_AGENT_CONFIG=1 bash modules/agents.sh --apply --only claude
```

## Safe Change Workflow

```text
Audit → Edit source → Review diff → Apply one target → Restart → Runtime verify
```

Example OpenCode change:

```bash
bash modules/agents.sh --audit --only opencode
$EDITOR config/opencode/opencode.json
bash test/agents-test.sh
bash scripts/privacy-scan.sh
bash modules/agents.sh --apply --only opencode --force
```

Quit and restart OpenCode after any configuration, agent, skill, command, or plugin change.
Start a new Claude or Codex session after configuration changes. Pi extensions may support
`/reload`; restart Pi for settings or package changes.

## Secrets

Prefer Keychain, a password manager, or a short-lived credential helper. If shell injection is
required, load values from an owner-only local file that is excluded from Git and backup tools.
The committed `config/agents/env.example` contains names only.

When replacing an insecure credential:

1. Identify every consumer, scope, and expiry.
2. Create the replacement credential.
3. Update consumers and verify the replacement.
4. Revoke the old credential.
5. Remove the old value from settings and backups without preserving another secret copy.

If exposure is confirmed, revoke first and accept emergency interruption.

## Third-Party Components

`config/agents/sources.tsv` records third-party ownership. Upgrade one component at a time with
its upstream installer, then run the audit and tool-specific diagnostics. Do not manually edit
generated output because the next upstream update will overwrite it.

## Deliberately Excluded

- Authentication files, OAuth locks, credentials, cookies, and private MCP URLs.
- Sessions, transcripts, prompts, shell snapshots, memories, histories, and tasks.
- Databases, caches, logs, backups, downloaded models, and generated catalogs.
- Codex project trust records, hook hashes, marketplace state, and application paths.
- Third-party package checkouts and generated installation trees.
