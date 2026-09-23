import { describe, expect, test } from 'bun:test';
import { chmod, mkdir, mkdtemp, readFile, stat, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

import {
  buildMonitorReport,
  parseHookPayload,
  recordHookEvent,
} from '../config/agents/codex-monitor';

const promptPayload = JSON.stringify({
  session_id: 'session-private-1',
  cwd: '/work/private-project',
  prompt: 'do not persist this prompt',
});

describe('Codex latency monitor privacy boundary', () => {
  test('accepts only bounded hook metadata and ignores hook content', () => {
    expect(parseHookPayload(promptPayload)).toEqual({
      sessionID: 'session-private-1',
      cwd: '/work/private-project',
    });
    expect(parseHookPayload('{broken')).toBeNull();
    expect(parseHookPayload('x'.repeat(70_000))).toBeNull();
    expect(parseHookPayload(JSON.stringify({ session_id: '', cwd: '/tmp' }))).toBeNull();
  });

  test('records metadata-only turn timing with private permissions', async () => {
    const root = await mkdtemp(join(tmpdir(), 'codex-monitor-'));
    const stateRoot = join(root, 'state');

    await recordHookEvent({
      stateRoot,
      event: 'prompt_started',
      rawPayload: promptPayload,
      now: new Date('2026-08-27T12:00:00.000Z'),
    });
    await recordHookEvent({
      stateRoot,
      event: 'tool_completed',
      rawPayload: promptPayload,
      now: new Date('2026-08-27T12:00:10.000Z'),
    });
    await recordHookEvent({
      stateRoot,
      event: 'stop_completed',
      rawPayload: promptPayload,
      now: new Date('2026-08-27T12:00:25.000Z'),
    });

    const files = Array.from(new Bun.Glob('events-*.ndjson').scanSync(stateRoot));
    expect(files).toHaveLength(1);
    const eventPath = join(stateRoot, files[0]!);
    const eventText = await readFile(eventPath, 'utf8');
    for (const forbidden of [
      'session-private-1',
      '/work/private-project',
      'do not persist this prompt',
    ]) {
      expect(eventText).not.toContain(forbidden);
    }
    expect((await stat(stateRoot)).mode & 0o777).toBe(0o700);
    expect((await stat(eventPath)).mode & 0o777).toBe(0o600);

    const report = await buildMonitorReport({
      stateRoot,
      now: new Date('2026-08-27T12:00:30.000Z'),
      staleAfterMs: 60_000,
    });
    expect(report.turns).toHaveLength(1);
    expect(report.turns[0]).toMatchObject({
      status: 'completed',
      totalMs: 25_000,
      timeToFirstToolMs: 10_000,
      finalizationMs: 15_000,
      toolCompletedCount: 1,
      maxQuietMs: 15_000,
      suspectedPhase: null,
    });
  });

  test('flags an incomplete turn by the last observable phase', async () => {
    const root = await mkdtemp(join(tmpdir(), 'codex-monitor-'));
    const stateRoot = join(root, 'state');

    await recordHookEvent({
      stateRoot,
      event: 'prompt_started',
      rawPayload: promptPayload,
      now: new Date('2026-08-27T12:00:00.000Z'),
    });
    await recordHookEvent({
      stateRoot,
      event: 'tool_completed',
      rawPayload: promptPayload,
      now: new Date('2026-08-27T12:00:05.000Z'),
    });

    const report = await buildMonitorReport({
      stateRoot,
      now: new Date('2026-08-27T12:03:05.000Z'),
      staleAfterMs: 120_000,
    });
    expect(report.turns[0]).toMatchObject({
      status: 'stalled',
      currentQuietMs: 180_000,
      toolCompletedCount: 1,
      suspectedPhase: 'model_after_last_tool_or_hook_before_stop',
    });
  });

  test('marks a previous unfinished turn interrupted when a new prompt arrives', async () => {
    const root = await mkdtemp(join(tmpdir(), 'codex-monitor-'));
    const stateRoot = join(root, 'state');

    await recordHookEvent({
      stateRoot,
      event: 'prompt_started',
      rawPayload: promptPayload,
      now: new Date('2026-08-27T12:00:00.000Z'),
    });
    await recordHookEvent({
      stateRoot,
      event: 'prompt_started',
      rawPayload: promptPayload,
      now: new Date('2026-08-27T12:01:00.000Z'),
    });

    const report = await buildMonitorReport({
      stateRoot,
      now: new Date('2026-08-27T12:01:10.000Z'),
      staleAfterMs: 120_000,
    });
    expect(report.turns).toHaveLength(2);
    expect(report.turns[0]).toMatchObject({ status: 'interrupted', totalMs: 60_000 });
    expect(report.turns[1]).toMatchObject({
      status: 'running',
      suspectedPhase: 'model_before_first_tool_or_answer',
    });
  });

  test('ignores malformed and oversized persisted records', async () => {
    const root = await mkdtemp(join(tmpdir(), 'codex-monitor-'));
    const stateRoot = join(root, 'state');
    await mkdir(stateRoot, { mode: 0o700 });
    const logPath = join(stateRoot, 'events-2026-08-27.ndjson');
    const invalidTimestamp = JSON.stringify({
      v: 1,
      at: 'not-a-date',
      event: 'prompt_started',
    });
    await writeFile(
      logPath,
      `${invalidTimestamp}\n{broken}\n${'x'.repeat(5000)}\n`,
      { mode: 0o600 },
    );
    await chmod(logPath, 0o600);

    const report = await buildMonitorReport({
      stateRoot,
      now: new Date('2026-08-27T12:00:00.000Z'),
      staleAfterMs: 120_000,
    });
    expect(report.turns).toEqual([]);
  });

  test('rotates expired daily logs without touching unrelated state', async () => {
    const root = await mkdtemp(join(tmpdir(), 'codex-monitor-'));
    const stateRoot = join(root, 'state');
    await mkdir(stateRoot, { mode: 0o700 });
    await writeFile(join(stateRoot, 'events-2026-08-01.ndjson'), '{}\n', { mode: 0o600 });
    await writeFile(join(stateRoot, 'keep.txt'), 'unrelated state\n', { mode: 0o600 });

    await recordHookEvent({
      stateRoot,
      event: 'prompt_started',
      rawPayload: promptPayload,
      now: new Date('2026-08-27T12:00:00.000Z'),
    });

    expect(Bun.file(join(stateRoot, 'events-2026-08-01.ndjson')).exists()).resolves.toBe(false);
    expect(Bun.file(join(stateRoot, 'keep.txt')).exists()).resolves.toBe(true);
  });

  test('stops appending when the private daily log reaches its size cap', async () => {
    const root = await mkdtemp(join(tmpdir(), 'codex-monitor-'));
    const stateRoot = join(root, 'state');
    await mkdir(stateRoot, { mode: 0o700 });
    const logPath = join(stateRoot, 'events-2026-08-27.ndjson');
    await writeFile(logPath, 'x'.repeat(4_000_000), { mode: 0o600 });

    expect(
      await recordHookEvent({
        stateRoot,
        event: 'prompt_started',
        rawPayload: promptPayload,
        now: new Date('2026-08-27T12:00:00.000Z'),
      }),
    ).toBe(false);
    expect((await stat(logPath)).size).toBe(4_000_000);
  });

  test('hook CLI fails open and report CLI emits machine-readable JSON', async () => {
    const root = await mkdtemp(join(tmpdir(), 'codex-monitor-cli-'));
    const monitor = join(import.meta.dir, '..', 'config', 'agents', 'codex-monitor.ts');
    const hook = Bun.spawn([process.execPath, monitor, 'hook'], {
      env: {
        ...process.env,
        CODEX_MONITOR_EVENT: 'UserPromptSubmit',
        CODEX_MONITOR_STATE_ROOT: join(root, 'state'),
      },
      stdin: 'pipe',
      stdout: 'pipe',
      stderr: 'pipe',
    });
    await hook.stdin.write(promptPayload);
    await hook.stdin.end();
    expect(await hook.exited).toBe(0);
    expect(await new Response(hook.stdout).text()).toBe('');

    const report = Bun.spawn(
      [process.execPath, monitor, 'report', '--format', 'json', '--stale-seconds', '60'],
      {
        env: { ...process.env, CODEX_MONITOR_STATE_ROOT: join(root, 'state') },
        stdout: 'pipe',
        stderr: 'pipe',
      },
    );
    expect(await report.exited).toBe(0);
    const output = JSON.parse(await new Response(report.stdout).text());
    expect(output).toMatchObject({ schemaVersion: 1, staleAfterMs: 60_000 });
    expect(output.turns[0]).toMatchObject({ status: 'running', toolCompletedCount: 0 });
  });

  test('Codex hooks monitor every observable phase with a one-second failure bound', async () => {
    const config = JSON.parse(
      await Bun.file(join(import.meta.dir, '..', 'config', 'codex', 'hooks.json')).text(),
    ) as Record<string, any>;
    for (const event of ['UserPromptSubmit', 'PostToolUse', 'Stop']) {
      const handlers = config.hooks[event][0].hooks as Array<Record<string, unknown>>;
      const monitor = handlers.find((handler) =>
        String(handler.command).includes('codex-monitor hook'),
      );
      expect(monitor).toBeDefined();
      expect(monitor?.timeout).toBe(1);
      expect(String(monitor?.command)).toContain(`CODEX_MONITOR_EVENT=${event}`);
      expect(String(monitor?.command)).toContain('|| true');
    }
    const promptHandlers = config.hooks.UserPromptSubmit[0].hooks as Array<Record<string, unknown>>;
    const stopHandlers = config.hooks.Stop[0].hooks as Array<Record<string, unknown>>;
    expect(String(promptHandlers[0]?.command)).toContain('codex-monitor hook');
    expect(String(stopHandlers.at(-1)?.command)).toContain('codex-monitor hook');
  });
});
