---
name: dispatch
description: 用 Herdr worktree-dispatcher 派发任务
allowed-tools: Bash
---

# dispatch

Use the worktree-dispatcher skill to dispatch this task: $ARGUMENTS

Requirements:
- Do not implement directly in the current checkout.
- Follow the worktree-dispatcher skill rules.
- Use `add --merge`.
- If this is analysis, review, explanation, or planning, require a committed Markdown report artifact.
- After dispatching, report branch, worktree path, agent name, cleanup log path, and whether a merge command exists, then stop.
