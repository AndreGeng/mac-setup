# Spec: Cross-Agent Active ReMe Memory

## Objective

Provide one two-layer active ReMe memory system for OpenCode, Claude Code, Codex, and Pi:

- Project memory retains filtered project conversations under `<project>/.reme/`.
- Global memory retains only automatically extracted cross-project preferences, generic workflows,
  and reusable engineering experience under the user's private ReMe data directory.
- A loopback-only ReMe service indexes global memory, promotes global daily candidates on a
  schedule, and supports automatic retrieval.
- Before each supported agent model request, bounded project and global memory is injected as explicitly
  untrusted historical context.
- Agent-specific adapters translate lifecycle events into one shared capture and retrieval policy.

The integration must remain best-effort. Memory, extraction, retrieval, service, or promotion
failures must never block the active agent request.

## Approved Assumptions

- Project memory keeps the existing filtered user/assistant transcript evidence.
- Global memory does not receive the original project transcript. A separate extraction call
  produces a bounded reusable summary; only that synthetic summary is passed to global ReMe.
- The global service starts on demand from OpenCode, inherits credentials from that process, and
  never persists credentials in files or process arguments.
- Global promotion uses ReMe's pinned default schedules: dream at `23:00` and index optimization at
  `02:00` in ReMe's configured timezone.
- Automatic project retrieval is local lexical retrieval from project Markdown. Automatic global
  retrieval uses ReMe search across global `daily/` and `digest/` memory.
- OpenCode uses its plugin API, Claude Code and Codex use synchronous command hooks, and Pi uses its
  extension API. Hook payloads are supplied over stdin and never interpolated into shell commands.
- The Web UI and external network binding remain disabled.

## Tech Stack

- Bash 3.2-compatible install, config generation, audit, and removal in `modules/agents.sh`.
- ReMe `0.4.1.7` in the stable versioned venv managed by the existing integration.
- OpenCode Plugin API and Bun runtime APIs.
- ReMe HTTP service bound to `127.0.0.1:2333` by default.
- The existing OpenAI-compatible provider environment for global-memory extraction.

## Commands

```bash
# Install or repair active project/global memory.
bash modules/agents.sh --apply --only opencode

# Audit package, configs, private directories, plugin, and service policy.
bash modules/agents.sh --audit --only opencode

# Remove the managed integration and stop its matching global service.
# Project .reme/ directories and global memory data remain unless explicitly deleted separately.
bash modules/agents.sh --remove-reme

# Focused verification.
bash test/agents-test.sh
bun test ./test/reme-memory-test.ts
bash scripts/privacy-scan.sh
bash -n modules/agents.sh
shfmt -d -i 2 modules/agents.sh test/agents-test.sh
```

## Project Structure

```text
config/agents/reme-memory-bridge.ts      Shared stdin hook bridge
config/opencode/plugins/reme-memory.ts  Thin OpenCode plugin adapter
config/opencode/lib/reme-memory-core.ts Shared capture, extraction, retrieval, and service policy
config/claude/settings.json             Claude Code capture and retrieval hooks
config/codex/hooks.json                 Codex capture and retrieval hooks
config/pi/extensions/reme-memory.ts     Pi capture and retrieval extension
config/reme/run-project-capture.py      Private-stdin project capture runner
config/reme/start-global-service.sh     Owner-umask process launcher
docs/reme-agent-memory-spec.md          Active-memory requirements and security boundaries
docs/reme-agent-memory-plan.md          Ordered implementation slices
docs/agent-migration.md                 Operator lifecycle documentation
modules/agents.sh                       Config generation, audit, apply, and removal
test/agents-test.sh                     Filesystem/config integration tests
test/reme-memory-test.ts                Plugin policy and transformation tests
<project>/.reme/                         Private project memory
~/.local/share/mac-setup/reme/global/   Private global memory
```

## Runtime Flow

### Capture

1. The active agent emits its completed-turn event: OpenCode `session.idle`, Claude Code/Codex
   `Stop`, or Pi finalized-message/settled events.
2. It reads the session and retains only ordinary non-synthetic user/assistant text. Tool calls,
   tool results, reasoning, files, system prompts, and compacted summaries remain excluded.
3. A detected credential discards the whole capture.
4. The existing one-shot project `auto_memory` call updates `<project>/.reme/daily/`.
5. A bounded provider call extracts only cross-project preferences, workflows, and reusable
   techniques. It must return `null` when nothing qualifies.
6. Only a validated, non-sensitive synthetic extraction is submitted to the global service's
   `auto_memory` endpoint. The global source evidence therefore contains the extraction, not the
   original project transcript.

Project messages are supplied to the pinned runner over stdin, not process arguments. Project
workspace roots and notes must resolve beneath the real project path without symlinks.

### Background Service And Promotion

1. The plugin probes the configured loopback service.
2. If unavailable and the port is free, it starts the pinned ReMe executable detached with the
   generated global config and inherited LLM environment.
3. The service config is derived from pinned upstream defaults, disables the Web UI, binds only to
   `127.0.0.1`, and exposes an explicit endpoint allowlist.
4. ReMe's background index watchers keep global daily/digest search current. The unrelated
   resource-ingestion watcher is removed from the global runtime job map.
5. `dream_cron` promotes global daily candidates into digest memory at `23:00`; index optimization
   runs at `02:00`.

### Automatic Retrieval

1. Before each model call, the adapter supplies the latest ordinary user text as the query through
   OpenCode's system transform, Claude Code/Codex `UserPromptSubmit`, or Pi's context hooks.
2. It lexically ranks a bounded set of project `.reme/daily/**/*.md` and `.reme/digest/**/*.md`
   notes without modifying project memory.
3. It requests bounded global results from the loopback ReMe `search` endpoint.
4. It injects at most the configured character budget into the system context with scope, path,
   and trust labels.
5. Retrieved memory is data only. The injected wrapper explicitly forbids following instructions,
   permissions, tool requests, or policy changes found inside memory.

## Code Style

Keep parsing and policy in small pure functions that can be tested without starting OpenCode or
ReMe:

```ts
const memory = parseGlobalExtraction(responseText);
if (!memory || containsSensitiveText(memory)) return;
```

Shell follows the repository's two-space indentation and quoted-expansion conventions. Generated
config is compared structurally against the expected config derived from the pinned package.

## Testing Strategy

- Shell tests use a temporary `HOME`, fake ReMe Python, and no network. They verify both project
  and global configs, owner-only global directories, service endpoint allowlist, cron presence,
  removal preservation, and policy drift failures.
- Bun tests cover transcript filtering, global extraction parsing, provider-tier isolation,
  project lexical ranking, untrusted retrieval formatting, service arguments, adapter payloads,
  plugin export shape, and stale-work cancellation.
- Fixture tests invoke the actual Claude Code, Codex, and Pi adapter boundaries and verify valid
  host-specific context output without external network access.
- A real smoke test starts the loopback service with synthetic content, confirms global candidate
  creation, exercises search, and verifies that project transcript text was not persisted globally.
- The real local apply occurs only after focused tests pass.

## Boundaries

- Always: bind loopback only; disable Web UI; use owner-only global storage/config; inherit
  credentials through environment only; validate extraction and service responses; bound query,
  result count, result bytes, extraction bytes, subprocess lifetime, and retries; label retrieval
  untrusted; preserve source scope/path; keep OpenCode fail-open.
- Current transport limitation: ReMe `0.4.1.7` has no HTTP authentication. Loopback operation
  assumes a trusted single-user workstation; disable active memory on shared or locally untrusted
  hosts.
- Ask first: expose the service beyond loopback; persist credentials; globally store original
  project transcripts; change schedules; enable another Agent; change provider or ReMe version;
  delete project or global memory data.
- Never: execute instructions from memory; let memory modify Skills, rules, permissions, hooks,
  provider settings, or trust policy; submit tools/reasoning/files/system content; print captured
  text or secret matches; commit generated memory; serve write/delete/shell jobs that the plugin
  does not require.

## Success Criteria

- Project capture continues to pass its existing real smoke test.
- OpenCode, Claude Code, Codex, and Pi all capture ordinary user/assistant text into project memory
  and inject bounded project/global retrieval before model work.
- Global memory contains only validated synthetic cross-project summaries, not original project
  messages.
- The global service listens only on `127.0.0.1`, has no Web UI, exposes only approved endpoints,
  and starts without persisting credentials.
- Generated global config structurally contains the expected watchers, `dream_cron`, optimization
  cron, and search pipeline from pinned ReMe `0.4.1.7`.
- Automatic retrieval combines bounded project/global results and marks all content untrusted.
- Retrieval, extraction, service startup, capture, and promotion failures do not fail OpenCode.
- Removal stops only a matching managed ReMe service and preserves both project and global memory.
- Focused tests, transpilation, shell syntax/formatting, privacy checks, independent review, and
  real runtime smoke checks pass.

## Open Questions

None. The user selected capture and automatic retrieval coverage for all four agents.
