#!/usr/bin/env bun

import {
  appendFile,
  chmod,
  mkdir,
  readFile,
  readdir,
  stat,
  unlink,
  writeFile,
} from 'node:fs/promises';
import { homedir } from 'node:os';
import { join } from 'node:path';

const MAX_STDIN_BYTES = 64_000;
const MAX_RECORD_BYTES = 1_024;
const MAX_DAILY_BYTES = 4_000_000;
const RETENTION_DAYS = 14;

export type MonitorEvent = 'prompt_started' | 'tool_completed' | 'stop_completed';

type HookMetadata = {
  sessionID: string;
  cwd: string;
};

type StoredEvent = {
  v: 1;
  at: string;
  event: MonitorEvent;
  session: string;
  project: string;
};

export type TurnReport = {
  sessionHash: string;
  projectHash: string;
  turn: number;
  status: 'completed' | 'interrupted' | 'running' | 'stalled';
  startedAt: string;
  stoppedAt: string | null;
  totalMs: number;
  timeToFirstToolMs: number | null;
  finalizationMs: number | null;
  toolCompletedCount: number;
  maxQuietMs: number;
  currentQuietMs: number | null;
  suspectedPhase:
    | 'model_before_first_tool_or_answer'
    | 'model_after_last_tool_or_hook_before_stop'
    | null;
};

export type MonitorReport = {
  schemaVersion: 1;
  generatedAt: string;
  retentionDays: number;
  staleAfterMs: number;
  turns: TurnReport[];
};

type ActiveTurn = {
  sessionHash: string;
  projectHash: string;
  turn: number;
  startedAt: Date;
  lastActivityAt: Date;
  firstToolAt: Date | null;
  lastToolAt: Date | null;
  toolCompletedCount: number;
  maxQuietMs: number;
};

function byteLength(value: string): number {
  return new TextEncoder().encode(value).byteLength;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return Boolean(value) && typeof value === 'object' && !Array.isArray(value);
}

export function parseHookPayload(text: string): HookMetadata | null {
  if (byteLength(text) > MAX_STDIN_BYTES) return null;
  try {
    const value: unknown = JSON.parse(text);
    if (!isRecord(value)) return null;
    const sessionID = value.session_id;
    const cwd = value.cwd;
    if (
      typeof sessionID !== 'string' ||
      sessionID.length === 0 ||
      sessionID.length > 512 ||
      typeof cwd !== 'string' ||
      cwd.length === 0 ||
      cwd.length > 4096
    ) {
      return null;
    }
    return { sessionID, cwd };
  } catch {
    return null;
  }
}

async function ensurePrivateDirectory(path: string): Promise<void> {
  await mkdir(path, { recursive: true, mode: 0o700 });
  await chmod(path, 0o700);
}

async function loadOrCreateSalt(stateRoot: string): Promise<string> {
  const path = join(stateRoot, '.salt');
  try {
    return (await readFile(path, 'utf8')).trim();
  } catch (error) {
    if (!(error instanceof Error) || !('code' in error) || error.code !== 'ENOENT') throw error;
  }

  const salt = crypto.randomUUID().replaceAll('-', '') + crypto.randomUUID().replaceAll('-', '');
  try {
    await writeFile(path, `${salt}\n`, { flag: 'wx', mode: 0o600 });
  } catch (error) {
    if (!(error instanceof Error) || !('code' in error) || error.code !== 'EEXIST') throw error;
    return (await readFile(path, 'utf8')).trim();
  }
  await chmod(path, 0o600);
  return salt;
}

function privateDigest(salt: string, kind: 'session' | 'project', value: string): string {
  return new Bun.CryptoHasher('sha256')
    .update(`${salt}\0${kind}\0${value}`)
    .digest('hex')
    .slice(0, 24);
}

function dailyEventName(now: Date): string {
  return `events-${now.toISOString().slice(0, 10)}.ndjson`;
}

async function removeExpiredLogs(stateRoot: string, now: Date): Promise<void> {
  const oldest = new Date(now.getTime() - RETENTION_DAYS * 86_400_000);
  const names = await readdir(stateRoot).catch(() => [] as string[]);
  await Promise.all(
    names.map(async (name) => {
      const match = /^events-(\d{4}-\d{2}-\d{2})\.ndjson$/.exec(name);
      if (!match) return;
      const date = new Date(`${match[1]}T00:00:00.000Z`);
      if (!Number.isFinite(date.getTime()) || date >= oldest) return;
      await unlink(join(stateRoot, name)).catch(() => undefined);
    }),
  );
}

export async function recordHookEvent(options: {
  stateRoot: string;
  event: MonitorEvent;
  rawPayload: string;
  now?: Date;
}): Promise<boolean> {
  const input = parseHookPayload(options.rawPayload);
  if (!input) return false;
  const now = options.now ?? new Date();
  if (!Number.isFinite(now.getTime())) return false;

  await ensurePrivateDirectory(options.stateRoot);
  const salt = await loadOrCreateSalt(options.stateRoot);
  const record: StoredEvent = {
    v: 1,
    at: now.toISOString(),
    event: options.event,
    session: privateDigest(salt, 'session', input.sessionID),
    project: privateDigest(salt, 'project', input.cwd),
  };
  const line = `${JSON.stringify(record)}\n`;
  if (byteLength(line) > MAX_RECORD_BYTES) return false;

  const path = join(options.stateRoot, dailyEventName(now));
  const currentSize = await stat(path).then((value) => value.size).catch(() => 0);
  if (currentSize + byteLength(line) > MAX_DAILY_BYTES) return false;
  await appendFile(path, line, { encoding: 'utf8', mode: 0o600 });
  await chmod(path, 0o600);
  await removeExpiredLogs(options.stateRoot, now).catch(() => undefined);
  return true;
}

function parseStoredEvent(line: string): StoredEvent | null {
  if (!line || byteLength(line) > MAX_RECORD_BYTES) return null;
  try {
    const value: unknown = JSON.parse(line);
    if (!isRecord(value)) return null;
    const timestamp = typeof value.at === 'string' ? new Date(value.at) : new Date(Number.NaN);
    if (
      value.v !== 1 ||
      !Number.isFinite(timestamp.getTime()) ||
      !['prompt_started', 'tool_completed', 'stop_completed'].includes(String(value.event)) ||
      typeof value.session !== 'string' ||
      !/^[a-f0-9]{24}$/.test(value.session) ||
      typeof value.project !== 'string' ||
      !/^[a-f0-9]{24}$/.test(value.project)
    ) {
      return null;
    }
    return value as StoredEvent;
  } catch {
    return null;
  }
}

function observeGap(turn: ActiveTurn, at: Date): void {
  turn.maxQuietMs = Math.max(turn.maxQuietMs, at.getTime() - turn.lastActivityAt.getTime());
  turn.lastActivityAt = at;
}

function finishTurn(
  turn: ActiveTurn,
  stoppedAt: Date,
  status: 'completed' | 'interrupted',
): TurnReport {
  observeGap(turn, stoppedAt);
  return {
    sessionHash: turn.sessionHash,
    projectHash: turn.projectHash,
    turn: turn.turn,
    status,
    startedAt: turn.startedAt.toISOString(),
    stoppedAt: stoppedAt.toISOString(),
    totalMs: stoppedAt.getTime() - turn.startedAt.getTime(),
    timeToFirstToolMs: turn.firstToolAt
      ? turn.firstToolAt.getTime() - turn.startedAt.getTime()
      : null,
    finalizationMs:
      status === 'completed'
        ? stoppedAt.getTime() - (turn.lastToolAt ?? turn.startedAt).getTime()
        : null,
    toolCompletedCount: turn.toolCompletedCount,
    maxQuietMs: turn.maxQuietMs,
    currentQuietMs: null,
    suspectedPhase: null,
  };
}

function activeTurnReport(turn: ActiveTurn, now: Date, staleAfterMs: number): TurnReport {
  const currentQuietMs = Math.max(0, now.getTime() - turn.lastActivityAt.getTime());
  return {
    sessionHash: turn.sessionHash,
    projectHash: turn.projectHash,
    turn: turn.turn,
    status: currentQuietMs >= staleAfterMs ? 'stalled' : 'running',
    startedAt: turn.startedAt.toISOString(),
    stoppedAt: null,
    totalMs: Math.max(0, now.getTime() - turn.startedAt.getTime()),
    timeToFirstToolMs: turn.firstToolAt
      ? turn.firstToolAt.getTime() - turn.startedAt.getTime()
      : null,
    finalizationMs: null,
    toolCompletedCount: turn.toolCompletedCount,
    maxQuietMs: Math.max(turn.maxQuietMs, currentQuietMs),
    currentQuietMs,
    suspectedPhase:
      turn.toolCompletedCount === 0
        ? 'model_before_first_tool_or_answer'
        : 'model_after_last_tool_or_hook_before_stop',
  };
}

export async function buildMonitorReport(options: {
  stateRoot: string;
  now?: Date;
  staleAfterMs?: number;
  limit?: number;
}): Promise<MonitorReport> {
  const now = options.now ?? new Date();
  const staleAfterMs = options.staleAfterMs ?? 120_000;
  const limit = options.limit ?? 50;
  const names = await readdir(options.stateRoot).catch(() => [] as string[]);
  const eventFiles = names
    .filter((name) => /^events-\d{4}-\d{2}-\d{2}\.ndjson$/.test(name))
    .sort();
  const events: StoredEvent[] = [];
  for (const name of eventFiles) {
    const path = join(options.stateRoot, name);
    const size = await stat(path).then((value) => value.size).catch(() => MAX_DAILY_BYTES + 1);
    if (size > MAX_DAILY_BYTES) continue;
    const text = await readFile(path, 'utf8').catch(() => '');
    for (const line of text.split('\n')) {
      const event = parseStoredEvent(line);
      if (event) events.push(event);
    }
  }
  events.sort((left, right) => left.at.localeCompare(right.at));

  const active = new Map<string, ActiveTurn>();
  const turnCounts = new Map<string, number>();
  const turns: TurnReport[] = [];
  for (const event of events) {
    const at = new Date(event.at);
    const current = active.get(event.session);
    if (event.event === 'prompt_started') {
      if (current) turns.push(finishTurn(current, at, 'interrupted'));
      const turn = (turnCounts.get(event.session) ?? 0) + 1;
      turnCounts.set(event.session, turn);
      active.set(event.session, {
        sessionHash: event.session,
        projectHash: event.project,
        turn,
        startedAt: at,
        lastActivityAt: at,
        firstToolAt: null,
        lastToolAt: null,
        toolCompletedCount: 0,
        maxQuietMs: 0,
      });
      continue;
    }
    if (!current) continue;
    if (event.event === 'tool_completed') {
      observeGap(current, at);
      current.firstToolAt ??= at;
      current.lastToolAt = at;
      current.toolCompletedCount += 1;
      continue;
    }
    turns.push(finishTurn(current, at, 'completed'));
    active.delete(event.session);
  }
  for (const turn of active.values()) turns.push(activeTurnReport(turn, now, staleAfterMs));
  turns.sort((left, right) => left.startedAt.localeCompare(right.startedAt));

  return {
    schemaVersion: 1,
    generatedAt: now.toISOString(),
    retentionDays: RETENTION_DAYS,
    staleAfterMs,
    turns: turns.slice(-Math.max(1, Math.min(limit, 500))),
  };
}

function stateRootFromEnvironment(): string {
  const home = process.env.HOME || homedir();
  const stateHome = process.env.XDG_STATE_HOME || join(home, '.local', 'state');
  return process.env.CODEX_MONITOR_STATE_ROOT || join(stateHome, 'mac-setup', 'codex-monitor');
}

async function readBoundedStdin(): Promise<string | null> {
  const chunks: Uint8Array[] = [];
  let total = 0;
  for await (const chunk of process.stdin) {
    const bytes = typeof chunk === 'string' ? new TextEncoder().encode(chunk) : chunk;
    total += bytes.byteLength;
    if (total > MAX_STDIN_BYTES) return null;
    chunks.push(bytes);
  }
  const result = new Uint8Array(total);
  let offset = 0;
  for (const chunk of chunks) {
    result.set(chunk, offset);
    offset += chunk.byteLength;
  }
  return new TextDecoder().decode(result);
}

function hookEventFromEnvironment(): MonitorEvent | null {
  switch (process.env.CODEX_MONITOR_EVENT) {
    case 'UserPromptSubmit':
      return 'prompt_started';
    case 'PostToolUse':
      return 'tool_completed';
    case 'Stop':
      return 'stop_completed';
    default:
      return null;
  }
}

function printTextReport(report: MonitorReport): void {
  if (report.turns.length === 0) {
    process.stdout.write('No Codex monitor events found.\n');
    return;
  }
  for (const turn of report.turns) {
    const phase = turn.suspectedPhase ? ` phase=${turn.suspectedPhase}` : '';
    process.stdout.write(
      `${turn.startedAt} session=${turn.sessionHash} turn=${turn.turn} status=${turn.status} ` +
        `total_ms=${turn.totalMs} tools=${turn.toolCompletedCount} max_quiet_ms=${turn.maxQuietMs}` +
        `${phase}\n`,
    );
  }
}

async function main(): Promise<number> {
  const command = process.argv[2] ?? 'report';
  if (command === 'hook') {
    try {
      const event = hookEventFromEnvironment();
      const rawPayload = await readBoundedStdin();
      if (event && rawPayload !== null) {
        await recordHookEvent({ stateRoot: stateRootFromEnvironment(), event, rawPayload });
      }
    } catch {}
    return 0;
  }
  if (command !== 'report') {
    process.stderr.write(
      'Usage: codex-monitor ' +
        '[report [--format text|json] [--stale-seconds N] [--limit N] | hook]\n',
    );
    return 2;
  }

  let format = 'text';
  let staleAfterMs = 120_000;
  let limit = 50;
  for (let index = 3; index < process.argv.length; index += 1) {
    const option = process.argv[index];
    const value = process.argv[index + 1];
    if (option === '--format' && ['text', 'json'].includes(value ?? '')) {
      format = value!;
      index += 1;
    } else if (option === '--stale-seconds' && /^\d+$/.test(value ?? '')) {
      staleAfterMs = Math.max(1, Number(value)) * 1000;
      index += 1;
    } else if (option === '--limit' && /^\d+$/.test(value ?? '')) {
      limit = Math.max(1, Math.min(500, Number(value)));
      index += 1;
    } else {
      process.stderr.write(`Invalid option: ${option ?? ''}\n`);
      return 2;
    }
  }
  const report = await buildMonitorReport({
    stateRoot: stateRootFromEnvironment(),
    staleAfterMs,
    limit,
  });
  if (format === 'json') process.stdout.write(`${JSON.stringify(report)}\n`);
  else printTextReport(report);
  return 0;
}

if (import.meta.main) process.exit(await main());
