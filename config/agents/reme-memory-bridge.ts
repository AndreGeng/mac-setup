#!/usr/bin/env bun
import { chmod, mkdir, readFile, realpath, rename, unlink, writeFile } from 'node:fs/promises';
import { homedir } from 'node:os';
import { dirname, join } from 'node:path';

import {
  captureMemoryTurn,
  containsSensitiveText,
  retrieveMemoryForTurn,
} from '../opencode/lib/reme-memory-core';

const MAX_STDIN_BYTES = 256_000;
const MAX_PROMPT_CHARS = 120_000;

type Host = 'claude' | 'codex' | 'pi';
type BridgeInput = {
  host: Host;
  event: 'UserPromptSubmit' | 'Stop';
  session_id: string;
  cwd: string;
  prompt?: string;
  last_assistant_message?: string;
};

type CaptureRequest = {
  directory: string;
  sessionID: string;
  userText: string;
  assistantText: string;
};

type BridgeDependencies = {
  stateRoot: string;
  retrieve(request: { directory: string; query: string }): Promise<string>;
  capture(request: CaptureRequest): Promise<void>;
};

function isBridgeInput(value: unknown): value is BridgeInput {
  if (!value || typeof value !== 'object' || Array.isArray(value)) return false;
  const input = value as Record<string, unknown>;
  if (!['claude', 'codex', 'pi'].includes(String(input.host))) return false;
  if (!['UserPromptSubmit', 'Stop'].includes(String(input.event))) return false;
  return (
    typeof input.session_id === 'string' &&
    input.session_id.length > 0 &&
    input.session_id.length <= 512 &&
    typeof input.cwd === 'string' &&
    input.cwd.length > 0 &&
    input.cwd.length <= 4096 &&
    (input.prompt === undefined || typeof input.prompt === 'string') &&
    (input.last_assistant_message === undefined ||
      typeof input.last_assistant_message === 'string')
  );
}

export function parseBridgeInput(text: string): BridgeInput | null {
  if (new TextEncoder().encode(text).byteLength > MAX_STDIN_BYTES) return null;
  try {
    const value: unknown = JSON.parse(text);
    return isBridgeInput(value) ? value : null;
  } catch {
    return null;
  }
}

export async function statePathFor(
  stateRoot: string,
  directory: string,
  sessionID: string,
): Promise<string> {
  const project = await realpath(directory);
  const digest = new Bun.CryptoHasher('sha256')
    .update(`${project}\0${sessionID}`)
    .digest('hex');
  return join(stateRoot, `${digest}.json`);
}

async function savePendingPrompt(path: string, prompt: string): Promise<void> {
  await mkdir(dirname(path), { recursive: true, mode: 0o700 });
  await chmod(dirname(path), 0o700);
  const temporary = `${path}.${process.pid}.tmp`;
  await writeFile(temporary, JSON.stringify({ prompt: prompt.slice(0, MAX_PROMPT_CHARS) }), {
    mode: 0o600,
  });
  await rename(temporary, path);
  await chmod(path, 0o600);
}

async function loadPendingPrompt(path: string): Promise<string | null> {
  const value: unknown = JSON.parse(await readFile(path, 'utf8'));
  if (!value || typeof value !== 'object' || Array.isArray(value)) return null;
  const prompt = (value as Record<string, unknown>).prompt;
  if (typeof prompt !== 'string' || !prompt || prompt.length > MAX_PROMPT_CHARS) return null;
  return prompt;
}

async function invalidatePendingPrompt(path: string): Promise<void> {
  await unlink(path).catch((error: NodeJS.ErrnoException) => {
    if (error.code !== 'ENOENT') throw error;
  });
}

async function consumePendingPrompt(path: string): Promise<string | null> {
  const consumedPath = `${path}.consumed.${process.pid}.${crypto.randomUUID()}`;
  try {
    await rename(path, consumedPath);
  } catch (error) {
    if (error instanceof Error && 'code' in error && (error as NodeJS.ErrnoException).code === 'ENOENT') {
      return null;
    }
    throw error;
  }
  try {
    return await loadPendingPrompt(consumedPath);
  } finally {
    await unlink(consumedPath).catch(() => undefined);
  }
}

async function writeStatus(
  stateRoot: string,
  stage: 'retrieve' | 'capture',
  success: boolean,
  errorCode: 'invalid-input' | 'state-error' | 'operation-error' | null,
): Promise<void> {
  await mkdir(stateRoot, { recursive: true, mode: 0o700 });
  await chmod(stateRoot, 0o700);
  const path = join(stateRoot, 'status.json');
  const temporary = `${path}.${process.pid}.tmp`;
  await writeFile(temporary, JSON.stringify({ stage, success, errorCode, timestamp: new Date().toISOString() }), {
    mode: 0o600,
  });
  await rename(temporary, path);
}

function retrievalOutput(host: Host, context: string): Record<string, unknown> {
  if (!context) return {};
  if (host === 'pi') return { additionalContext: context };
  return {
    hookSpecificOutput: {
      hookEventName: 'UserPromptSubmit',
      additionalContext: context,
    },
  };
}

export function createBridgeHandler(dependencies: BridgeDependencies) {
  return async (input: BridgeInput): Promise<Record<string, unknown>> => {
    try {
      const project = await realpath(input.cwd);
      const statePath = await statePathFor(dependencies.stateRoot, project, input.session_id);

      if (input.event === 'UserPromptSubmit') {
        await invalidatePendingPrompt(statePath);
        const prompt = input.prompt?.trim();
        if (!prompt || containsSensitiveText(prompt)) {
          await writeStatus(dependencies.stateRoot, 'retrieve', false, 'invalid-input').catch(() => undefined);
          return {};
        }
        await savePendingPrompt(statePath, prompt);
        const context = await dependencies.retrieve({ directory: project, query: prompt });
        await writeStatus(dependencies.stateRoot, 'retrieve', true, null).catch(() => undefined);
        return retrievalOutput(input.host, context);
      }

      const userText = await consumePendingPrompt(statePath);
      const assistantText = input.last_assistant_message?.trim();
      if (!assistantText || containsSensitiveText(assistantText)) return {};
      if (!userText || containsSensitiveText(userText)) return {};
      await dependencies.capture({
        directory: project,
        sessionID: input.session_id,
        userText,
        assistantText,
      });
      await writeStatus(dependencies.stateRoot, 'capture', true, null).catch(() => undefined);
      return {};
    } catch {
      await writeStatus(
        dependencies.stateRoot,
        input.event === 'Stop' ? 'capture' : 'retrieve',
        false,
        'operation-error',
      ).catch(() => undefined);
      return {};
    }
  };
}

const home = process.env.HOME || homedir();
const stateHome = process.env.XDG_STATE_HOME || join(home, '.local', 'state');

async function queueDetachedCapture(request: CaptureRequest): Promise<void> {
  const child = Bun.spawn([process.execPath, import.meta.path], {
    detached: true,
    env: { ...process.env, REME_HOOK_MODE: 'capture' },
    stdin: 'pipe',
    stdout: 'ignore',
    stderr: 'ignore',
  });
  await child.stdin.write(JSON.stringify(request));
  await child.stdin.end();
  child.unref();
}

const handler = createBridgeHandler({
  stateRoot: join(stateHome, 'mac-setup', 'reme-hooks'),
  retrieve: ({ directory, query }) => retrieveMemoryForTurn(directory, query),
  capture: queueDetachedCapture,
});

if (import.meta.main) {
  const raw = await Bun.stdin.text();
  if (process.env.REME_HOOK_MODE === 'capture') {
    try {
      const request = JSON.parse(raw) as CaptureRequest;
      if (
        typeof request.directory === 'string' &&
        typeof request.sessionID === 'string' &&
        typeof request.userText === 'string' &&
        typeof request.assistantText === 'string'
      ) {
        await captureMemoryTurn(request);
      }
    } catch {}
    process.exit(0);
  }
  let normalized = raw;
  try {
    const hostPayload = JSON.parse(raw) as Record<string, unknown>;
    normalized = JSON.stringify({
      ...hostPayload,
      host: process.env.REME_HOOK_HOST || hostPayload.host,
      event: process.env.REME_HOOK_EVENT || hostPayload.event,
    });
  } catch {}
  const input = parseBridgeInput(normalized);
  const output = input ? await handler(input) : {};
  process.stdout.write(`${JSON.stringify(output)}\n`);
}
