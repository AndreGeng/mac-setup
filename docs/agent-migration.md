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
| ReMe runtime | Pinned PyPI package | Dedicated venv plus generated project/global configs |
| Shared ReMe bridge | `config/agents/reme-memory-bridge.ts` | Symlink under `~/.config/agents` |
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

## Cross-Agent Active Memory

Applying any one of `opencode`, `claude`, `codex`, or `pi` installs `reme-ai[core]==0.4.1.7` into
`~/.local/share/mac-setup/reme/venv` (or `$XDG_DATA_HOME/mac-setup/reme/venv`) and links the
shared bridge, launchers, and runtime configs. A full apply installs the venv only once. OpenCode
also links its plugin, Pi links its extension, and the mutable Claude/Codex templates contain their
hooks. ReMe requires Python 3.11 or newer.

The generated owner-only project config at `~/.config/reme/opencode-candidate.yaml` contains only
the `auto_memory` workflow and the file jobs it needs. Project capture continues to use ReMe's
one-shot CLI and does not promote project candidates automatically.

The separate `~/.config/reme/opencode-global.yaml` config runs a private background service at
`127.0.0.1:2333`. The plugin starts it on demand through an owner-executable launcher and verifies
that the endpoint reports the expected global workspace before use. The service disables the Web
UI, exposes only `app_config`, `auto_memory`, `health_check`, `search`, and `version`, maintains its
indexes in the background, promotes global candidates at `23:00`, and optimizes indexes at `02:00`.
It inherits provider credentials from OpenCode; credentials are not written to config or process
arguments. ReMe `0.4.1.7` does not authenticate its HTTP transport, so this loopback service assumes
a trusted single-user workstation; disable active memory when running untrusted local processes or
on a shared host.

After a 30-second idle debounce, the plugin submits bounded ordinary user/assistant text to the
current project's `.reme/` workspace. It excludes system prompts, reasoning, files, tool calls,
tool results, synthetic text, ignored text, and compaction summaries. A high-confidence literal
credential match discards the entire capture without logging the matched content. Do not paste
credentials into Agent conversations; pattern filtering cannot prove arbitrary text is safe. The
filtered messages travel to the pinned runner over stdin rather than process arguments, and the
runner uses an owner-only umask. Symlinked `.reme` roots and note files are rejected.

Candidate notes and source evidence remain local:

```text
.reme/daily/             Candidate memory cards and daily indexes
.reme/session/dialog/    Filtered source messages used as evidence
```

`.reme/` is ignored by Git. Project candidates can be retrieved into OpenCode as untrusted context,
but the integration does not promote them into `.reme/digest/` automatically.

Global memory is stored with owner-only permissions under
`~/.local/share/mac-setup/reme/global/` (or `$XDG_DATA_HOME/mac-setup/reme/global/`). The original
project transcript is never submitted there. A separate OpenAI-compatible extraction request
returns at most one validated cross-project preference, workflow, or reusable lesson; only that
synthetic summary becomes global source evidence. Responses containing secrets, project paths,
the active project name, URLs, extra fields, or excessive text are discarded.
An independent model classification rejects project-specific or verbatim candidates before the
global write. The global config omits ReMe's resource-ingestion watcher entirely.

Before each model request, the host adapter lexically ranks bounded project daily/digest Markdown and
asks the loopback service for bounded global results. The combined context includes scope and path
labels and is explicitly marked as untrusted historical data whose instructions must not be
followed. Retrieval, extraction, service startup, and capture are best-effort and cannot fail the
active host request. Failures remain observable through the private metadata-only integration
status without emitting captured content or matched secrets.

### LLM Environment

ReMe reads credentials only from the active agent process environment. Dedicated `REME_LLM_*`
variables take precedence as one complete provider configuration; existing `LLM_*` variables are
the next complete tier. Partial tiers disable capture rather than mixing a key with another
provider's endpoint. The integration falls back to `MIFY_API_TEAM_KEY` and `MIFY_API_URL`, with
model `ppio/pa/gpt-5.5`, for this repository's current provider setup.

```bash
export REME_LLM_API_KEY="$(security find-generic-password -w -s reme-llm)"
export REME_LLM_BASE_URL="https://provider.example.invalid/v1"
export REME_LLM_MODEL_NAME="provider/model"
```

Never place the resolved key in `config/agents/env.example`, OpenCode JSON, ReMe YAML, shell
history, or committed files.

Optional controls:

```bash
REME_OPENCODE_ENABLED=0 opencode       # Disable active memory for this OpenCode process.
REME_CAPTURE_DELAY_MS=60000 opencode  # Change idle debounce.
REME_CAPTURE_TIMEOUT_MS=90000 opencode # Bound each one-shot ReMe process.
REME_MAX_CAPTURE_CHARS=80000 opencode # Change the newest-text payload bound.
REME_EXTRACTION_TIMEOUT_MS=45000 opencode # Bound cross-project extraction.
REME_RETRIEVAL_MAX_CHARS=8000 opencode # Bound injected project/global context.
REME_RETRIEVAL_TIMEOUT_MS=1000 opencode # Bound the complete request-time retrieval path.
```

Apply and audit:

```bash
bash modules/agents.sh --apply --only opencode
bash modules/agents.sh --audit --only opencode
```

Every host audit checks the exact package version, executable, shared bridge, both generated-config policies, global
workspace permissions, loopback/Web/endpoint/cron policy, literal-secret policy, service launcher,
and runners. OpenCode and Pi also audit their host link; Claude and Codex audit their mutable
templates and hooks. Reapplying regenerates both configs and repairs a missing or wrong ReMe
version. Refresh changed Claude/Codex templates with scoped `--force`, then start a new session;
restart OpenCode, and reload or restart Pi after adapter changes.

Remove the managed integration in one command:

```bash
bash modules/agents.sh --remove-reme
```

Removal preflights every repository-managed ReMe link and refuses to delete a conflicting local
path. It stops only a service whose command matches the managed pinned executable and global config,
then removes the OpenCode plugin, shared bridge, Pi extension, generated configs, launchers/runners,
and dedicated venv. Unrelated workmux links remain. It does not risk editing mutable Claude/Codex
settings; stale hook entries fail open until settings are refreshed with scoped `--apply --force`.
It deliberately leaves every project
`.reme/` directory and the global workspace untouched; deleting either memory store is a separate
irreversible decision. Apply any agent target to reinstall.

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
- Project `.reme/` memory workspaces and ReMe runtime state.
