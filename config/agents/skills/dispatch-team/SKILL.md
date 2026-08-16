---
name: dispatch-team
description: 用 Herdr worktree-dispatcher 小队模式派发任务
allowed-tools: Bash
---

# dispatch-team

Use the worktree-dispatcher skill team mode to dispatch this task: $ARGUMENTS

Requirements:
- Do not implement directly in the current checkout.
- Call dispatcher with `add --team engineering --merge`, passing only $ARGUMENTS as the task text.
- The leader pane is for communication and orchestration, not direct implementation.
- Do not call `team spawn` unless the user provided an existing `team_token`.
- If this is analysis, review, explanation, or planning, require a committed Markdown report artifact.
- Report the team token, profile, leader, shared worktree, branch, and merge command, then stop.
