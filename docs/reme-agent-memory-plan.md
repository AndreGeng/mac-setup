# Implementation Plan: Cross-Agent Active ReMe Memory

## Architecture Decisions

- Preserve the project candidate path as a separate failure domain and source of project-specific
  retrieval.
- Use one loopback global ReMe service for indexing, cron promotion, and cross-project search.
- Extract global reusable memory before storage so global ReMe never receives the original project
  transcript.
- Start the service from each host adapter so credentials remain environment-only; validate the service
  identity before using or stopping it.
- Inject retrieval through each host's supported pre-model hook as bounded, untrusted context.
- Put shared policy and ReMe I/O behind one stdin-only bridge; keep host adapters thin.
- Use synchronous pre-prompt hooks for Claude Code and Codex, and ephemeral Pi context mutation.

## Tasks

### Task 1: Specify Global Config And Storage

**Acceptance criteria:**

- Tests require an owner-only global workspace and generated global service config.
- Tests require loopback binding, disabled Web UI, endpoint allowlisting, watchers, `dream_cron`,
  and optimization cron.
- Audit rejects config drift, public binding, unsafe endpoints, wrong schedules, and unsafe modes.

**Verification:** `bash test/agents-test.sh` fails before implementation.

**Files:** `test/agents-test.sh`, `modules/agents.sh`

### Task 2: Implement And Verify Global Config

**Acceptance criteria:**

- Apply creates both project one-shot and global service configs from pinned upstream defaults.
- Global data directories are mode `700`; configs are mode `600`.
- Removal preserves global data while removing managed runtime config and plugin integration.

**Verification:** Shell integration tests and syntax/formatting checks pass.

**Files:** `modules/agents.sh`, `test/agents-test.sh`

### Checkpoint: Global Foundation

- Existing project capture remains green.
- Global policy tests pass without network or real-home mutation.

### Task 3: Fix And Guard OpenCode Plugin Loading

**Acceptance criteria:**

- The auto-loaded plugin entry exports only plugin functions.
- A loader-equivalent regression test initializes every export successfully.

**Verification:** `bun test ./test/reme-memory-test.ts`

**Files:** OpenCode plugin entry, shared core, Bun tests

### Task 4: Specify Extraction And Retrieval Policy

**Acceptance criteria:**

- Tests prove extraction accepts only the strict bounded response shape and rejects secrets,
  malformed data, project-specific content markers, and oversized output.
- Tests prove project ranking and global formatting preserve source/scope while treating content as
  untrusted.
- Tests prove service arguments contain no credentials.

**Verification:** `bun test ./test/reme-memory-test.ts` fails before implementation.

**Files:** `test/reme-memory-test.ts`

### Task 5: Implement Shared Service, Extraction, Capture, And Retrieval

**Acceptance criteria:**

- Plugin starts/probes the loopback service best-effort with inherited provider environment.
- Existing project capture runs unchanged.
- Global extraction stores only validated synthetic summaries through global `auto_memory`.

**Verification:** Bun tests and plugin transpilation pass.

**Files:** `config/opencode/plugins/reme-memory.ts`, `test/reme-memory-test.ts`

### Task 6: Integrate Claude Code And Codex Hooks

**Acceptance criteria:**

- `UserPromptSubmit` returns bounded `additionalContext` from ReMe.
- `Stop` captures the completed user/assistant turn without blocking the host.
- Commands receive host payloads only on stdin.

**Verification:** fixture tests plus `bash test/agents-test.sh`

### Task 7: Integrate Pi Extension

**Acceptance criteria:**

- Pi retrieves once per run and injects memory ephemerally before model calls.
- Finalized ordinary messages are captured without mutating conversation messages.

**Verification:** extension fixture tests plus installer tests

### Task 8: Implement Automatic Retrieval

**Acceptance criteria:**

- Latest user text drives bounded project lexical and global ReMe search.
- Injected system context contains trust instructions, scope, source, and bounded excerpts.
- Missing/corrupt memory or service failures produce no injected context and no user-facing error.

**Verification:** Bun tests cover empty, malformed, malicious, and oversized retrieval results.

**Files:** `config/opencode/plugins/reme-memory.ts`, `test/reme-memory-test.ts`

### Checkpoint: Active Memory

- Shell and Bun tests pass.
- Plugin transpiles.
- Independent security/correctness review has no blocking findings.

### Task 9: Install, Audit, Remove, Document, And Runtime Verify

**Acceptance criteria:**

- Documentation explains storage, schedules, cost, trust boundaries, disable/restart/removal, and
  data deletion as separate explicit operations.
- Applying any host independently installs the shared pinned runtime and bridge; OpenCode/Pi link
  their adapters and Claude/Codex templates retain their hooks.
- Audit covers shared policy plus host-specific integration, and safe removal preserves memory and
  unrelated links while leaving mutable Claude/Codex settings untouched.
- Synthetic smoke verifies service identity, global capture, search, digest boundary, and absence
  of original project transcript in global storage.

**Verification:** Run focused checks, privacy/security scans, local audit, smoke tests, and inspect
the complete diff/Git status.

**Files:** `docs/agent-migration.md`, `config/agents/env.example`, repository guidance as needed.

## Risks

| Risk | Mitigation |
|---|---|
| Global project-data leakage | Extract first; globally persist only validated synthetic reusable content. |
| Memory prompt injection | Delimit and label every result untrusted; never interpret it as policy/instruction. |
| Local service exposure | Bind `127.0.0.1`, disable Web UI, allowlist endpoints, validate identity. |
| Credential exposure | Environment inheritance only; no credential files, args, output, or logs. |
| Excess model cost | Debounce, deduplicate, return `null` for no global memory, and bound all payloads. |
| Stale/incorrect memory | Include source/scope/date, bound results, preserve project candidates for review. |
| Hung service/extraction | Timeouts, stale generation gates, and fail-open OpenCode hooks. |

## Open Questions

None.
