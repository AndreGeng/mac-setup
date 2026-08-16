# Agent Configuration Migration

The `agents` module restores stable configuration for OpenCode, Claude Code, Codex, Pi, and
two locally maintained dispatch skills.

## Install

```bash
bash modules/agents.sh
```

The module copies mutable application settings only when they do not exist. It symlinks
repository-owned plugins and skills so later Git updates take effect immediately.

To intentionally replace existing settings, with timestamped backups:

```bash
MAC_SETUP_FORCE_AGENT_CONFIG=1 bash modules/agents.sh
```

## Secrets

The repository contains only `config/agents/env.example`. Put real values in an ignored shell
file such as `~/.zshrc.local`, never in an agent settings file:

```bash
export MIFY_API_TEAM_KEY='...'
export MIFY_API_URL='...'
export MIFY_API_ANTHROPIC_URL='...'
export MIFY_API_SGP_URL='...'
export FEISHU_MCP_URL='...'
```

When both Mify URL variables are available, the module renders Pi's `models.json` locally.
The committed template contains no internal endpoint or credential.

## Third-party skills

`config/agents/sources.tsv` records third-party ownership. Reinstall these from upstream rather
than copying current agent homes:

- ECC owns most Claude agents, commands, rules, hooks, and engineering skills.
- gstack owns its workflow and browser skill suite.
- Lark CLI owns the `lark-*` skills under the shared agent root.
- GitNexus owns its seven code-graph skills.
- Herdr, cmux, and Orca own their generated hooks and integration extensions.

The current gstack installation can be reconstructed with its documented upstream flow:

```bash
git clone --single-branch --depth 1 https://github.com/garrytan/gstack.git ~/.claude/skills/gstack
(cd ~/.claude/skills/gstack && ./setup)
```

## Deliberately excluded

- `auth.json`, OAuth locks, credentials, cookies, and private MCP URLs.
- Sessions, transcripts, prompts, shell snapshots, memories, histories, and tasks.
- SQLite databases, caches, logs, backups, downloaded models, and generated catalogs.
- Codex project trust records, hook hashes, marketplace timestamps, and application paths.
- `node_modules`, Codex runtime packages, ChatGPT Computer Use, and the full gstack checkout.

After changing any OpenCode configuration, quit and restart OpenCode because it loads global
configuration only at startup.
