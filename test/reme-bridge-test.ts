import { describe, expect, test } from 'bun:test';
import { access, mkdir, mkdtemp, readFile, stat } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

import {
  createBridgeHandler,
  parseBridgeInput,
  statePathFor,
} from '../config/agents/reme-memory-bridge';
import registerReMeMemory from '../config/pi/extensions/reme-memory';

const promptPayload = {
  host: 'claude' as const,
  event: 'UserPromptSubmit' as const,
  session_id: 'session-1',
  cwd: '/work/project',
  prompt: 'How should focused verification work?',
};

describe('ReMe stdin bridge boundary', () => {
  test('parses host payloads and rejects malformed or oversized input', () => {
    expect(parseBridgeInput(JSON.stringify(promptPayload))).toEqual(promptPayload);
    expect(parseBridgeInput('{broken')).toBeNull();
    expect(parseBridgeInput('x'.repeat(300_000))).toBeNull();
  });

  test('uses private hashed state bound to session and real cwd', async () => {
    const root = await mkdtemp(join(tmpdir(), 'reme-bridge-'));
    const project = join(root, 'project');
    const state = join(root, 'state');
    await mkdir(project);

    const first = await statePathFor(state, project, 'session/private');
    const second = await statePathFor(state, project, 'other-session');

    expect(first).not.toContain('session/private');
    expect(first).not.toBe(second);
    expect(first.endsWith('.json')).toBe(true);
  });

  test('returns host-specific synchronous retrieval output and persists bounded pending text', async () => {
    const root = await mkdtemp(join(tmpdir(), 'reme-bridge-'));
    const project = join(root, 'project');
    const state = join(root, 'state');
    await mkdir(project);
    const retrieve = async () => '<untrusted-memory-context>bounded</untrusted-memory-context>';
    const capture = async () => {};
    const handler = createBridgeHandler({ stateRoot: state, retrieve, capture });

    const claude = await handler({ ...promptPayload, cwd: project, prompt: 'p'.repeat(200_000) });
    const codex = await handler({ ...promptPayload, host: 'codex', cwd: project });

    expect(claude).toEqual({
      hookSpecificOutput: {
        hookEventName: 'UserPromptSubmit',
        additionalContext: '<untrusted-memory-context>bounded</untrusted-memory-context>',
      },
    });
    expect(codex).toEqual({
      hookSpecificOutput: {
        hookEventName: 'UserPromptSubmit',
        additionalContext: '<untrusted-memory-context>bounded</untrusted-memory-context>',
      },
    });
    const stateFile = await statePathFor(state, project, 'session-1');
    expect((await stat(stateFile)).mode & 0o777).toBe(0o600);
    expect(JSON.parse(await readFile(stateFile, 'utf8')).prompt.length).toBeLessThanOrEqual(120_000);
  });

  test('rejects secret prompts and captures a completed turn best-effort without stdout data', async () => {
    const root = await mkdtemp(join(tmpdir(), 'reme-bridge-'));
    const project = join(root, 'project');
    await mkdir(project);
    const captured: unknown[] = [];
    const handler = createBridgeHandler({
      stateRoot: join(root, 'state'),
      retrieve: async () => 'must not appear',
      capture: async (request) => captured.push(request),
    });

    expect(
      await handler({ ...promptPayload, cwd: project, prompt: 'token=abcdefghijklmnopqrstuvwxyz123456' }),
    ).toEqual({});
    await handler({ ...promptPayload, cwd: project, prompt: 'ordinary prompt' });
    const output = await handler({
      host: 'claude',
      event: 'Stop',
      session_id: 'session-1',
      cwd: project,
      last_assistant_message: 'ordinary answer',
    });

    expect(output).toEqual({});
    expect(captured).toHaveLength(1);
    expect(captured[0]).toMatchObject({ userText: 'ordinary prompt', assistantText: 'ordinary answer' });
  });

  test('invalidates old state before every prompt and leaves no state for empty or secret prompts', async () => {
    const root = await mkdtemp(join(tmpdir(), 'reme-bridge-'));
    const project = join(root, 'project');
    const state = join(root, 'state');
    await mkdir(project);
    const captured: unknown[] = [];
    const handler = createBridgeHandler({
      stateRoot: state,
      retrieve: async () => '',
      capture: async (request) => captured.push(request),
    });
    const stateFile = await statePathFor(state, project, 'session-1');

    await handler({ ...promptPayload, cwd: project, prompt: 'old prompt' });
    await handler({ ...promptPayload, cwd: project, prompt: '   ' });
    expect(access(stateFile)).rejects.toThrow();
    await handler({ ...promptPayload, cwd: project, prompt: 'token=abcdefghijklmnopqrstuvwxyz123456' });
    expect(access(stateFile)).rejects.toThrow();
    await handler({
      host: 'claude', event: 'Stop', session_id: 'session-1', cwd: project,
      last_assistant_message: 'answer',
    });
    expect(captured).toHaveLength(0);
  });

  test('atomically consumes pending state before capture, including failed concurrent captures', async () => {
    const root = await mkdtemp(join(tmpdir(), 'reme-bridge-'));
    const project = join(root, 'project');
    const state = join(root, 'state');
    await mkdir(project);
    let captures = 0;
    const handler = createBridgeHandler({
      stateRoot: state,
      retrieve: async () => '',
      capture: async () => {
        captures += 1;
        throw new Error('capture failed');
      },
    });
    await handler({ ...promptPayload, cwd: project, prompt: 'one prompt' });
    const stop = {
      host: 'codex' as const, event: 'Stop' as const, session_id: 'session-1', cwd: project,
      last_assistant_message: 'one answer',
    };
    await Promise.all([handler(stop), handler(stop)]);
    await handler(stop);
    expect(captures).toBe(1);
  });

  test.each(['', 'token=abcdefghijklmnopqrstuvwxyz123456'])(
    'consumes pending state before rejecting assistant output %p',
    async (rejectedAssistantText) => {
      const root = await mkdtemp(join(tmpdir(), 'reme-bridge-'));
      const project = join(root, 'project');
      const state = join(root, 'state');
      await mkdir(project);
      const captured: unknown[] = [];
      const handler = createBridgeHandler({
        stateRoot: state,
        retrieve: async () => '',
        capture: async (request) => captured.push(request),
      });

      await handler({ ...promptPayload, cwd: project, prompt: 'must not become stale' });
      await handler({
        host: 'claude', event: 'Stop', session_id: 'session-1', cwd: project,
        last_assistant_message: rejectedAssistantText,
      });
      await handler({
        host: 'claude', event: 'Stop', session_id: 'session-1', cwd: project,
        last_assistant_message: 'later ordinary answer',
      });

      expect(captured).toHaveLength(0);
      expect(access(await statePathFor(state, project, 'session-1'))).rejects.toThrow();
    },
  );

  test('writes bounded metadata-only status without hook content or identifiers', async () => {
    const root = await mkdtemp(join(tmpdir(), 'reme-bridge-'));
    const project = join(root, 'project');
    const state = join(root, 'state');
    await mkdir(project);
    const handler = createBridgeHandler({
      stateRoot: state,
      retrieve: async () => 'private retrieved text',
      capture: async () => {},
    });
    await handler({ ...promptPayload, cwd: project });
    const statusText = await readFile(join(state, 'status.json'), 'utf8');
    const status = JSON.parse(statusText);
    expect(status).toMatchObject({ stage: 'retrieve', success: true, errorCode: null });
    expect(typeof status.timestamp).toBe('string');
    for (const forbidden of ['focused verification', 'private retrieved', project, 'session-1', '127.0.0.1']) {
      expect(statusText).not.toContain(forbidden);
    }
    expect(statusText.length).toBeLessThan(512);
  });

  test('fails open when retrieval, state, or capture fails', async () => {
    const handler = createBridgeHandler({
      stateRoot: '/dev/null/unwritable',
      retrieve: async () => {
        throw new Error('offline');
      },
      capture: async () => {
        throw new Error('offline');
      },
    });
    expect(await handler(promptPayload)).toEqual({});
  });
});

describe('Claude and Codex bridge subprocess protocol', () => {
  test.each(['claude', 'codex'] as const)('%s reads stdin, emits one JSON response, and exits zero', async (host) => {
    const root = await mkdtemp(join(tmpdir(), `reme-${host}-process-`));
    const project = join(root, 'project');
    await mkdir(project);
    const child = Bun.spawn([process.execPath, join(import.meta.dir, '..', 'config', 'agents', 'reme-memory-bridge.ts')], {
      env: {
        ...process.env,
        HOME: root,
        XDG_STATE_HOME: join(root, 'state-home'),
        REME_HOOK_HOST: host,
        REME_HOOK_EVENT: 'UserPromptSubmit',
      },
      stdin: 'pipe', stdout: 'pipe', stderr: 'pipe',
    });
    child.stdin.write(JSON.stringify({ session_id: 'fixture', cwd: project, prompt: 'fixture prompt' }));
    child.stdin.end();
    expect(await child.exited).toBe(0);
    expect(JSON.parse(await new Response(child.stdout).text())).toEqual({});
    expect(await new Response(child.stderr).text()).toBe('');

    const stop = Bun.spawn([process.execPath, join(import.meta.dir, '..', 'config', 'agents', 'reme-memory-bridge.ts')], {
      env: {
        ...process.env,
        HOME: root,
        XDG_STATE_HOME: join(root, 'state-home'),
        REME_HOOK_HOST: host,
        REME_HOOK_EVENT: 'Stop',
      },
      stdin: 'pipe', stdout: 'pipe', stderr: 'pipe',
    });
    stop.stdin.write(JSON.stringify({
      session_id: 'fixture', cwd: project, last_assistant_message: 'fixture answer',
    }));
    stop.stdin.end();
    expect(await stop.exited).toBe(0);
    expect(JSON.parse(await new Response(stop.stdout).text())).toEqual({});
    expect(await new Response(stop.stderr).text()).toBe('');
  });
});

describe('Pi ReMe extension', () => {
  test('preserves the system prompt and injects cached memory as one idempotent ephemeral message', async () => {
    const handlers = new Map<string, Function>();
    const executions: Array<{ command: string; args: string[]; options: unknown }> = [];
    const pi = {
      on: (name: string, handler: Function) => handlers.set(name, handler),
      exec: async (command: string, args: string[], options: unknown) => {
        executions.push({ command, args, options });
        return { stdout: JSON.stringify({ additionalContext: 'remember safely' }), stderr: '', code: 0 };
      },
    };
    registerReMeMemory(pi as any);

    expect([...handlers.keys()]).toEqual([
      'before_agent_start',
      'context',
      'message_end',
      'agent_settled',
      'session_shutdown',
    ]);
    const event = { prompt: 'ordinary prompt', systemPrompt: 'original system policy' };
    const context = {
      cwd: '/work/project',
      sessionManager: { getSessionId: () => 'documented-session-id' },
    };
    const result = await handlers.get('before_agent_start')!(event, context);
    expect(result).toEqual({ systemPrompt: 'original system policy' });
    expect(event).toEqual({ prompt: 'ordinary prompt', systemPrompt: 'original system policy' });

    const persistedMessages = [
      { role: 'user', content: 'persisted' },
      { role: 'custom', customType: 'reme-memory', content: 'stale copy', display: false },
    ];
    const contextEvent = { messages: persistedMessages };
    const firstContext = await handlers.get('context')!(contextEvent);
    const secondContext = await handlers.get('context')!({ messages: firstContext.messages });
    const expectedMessages = [
      { role: 'user', content: 'persisted' },
      {
        role: 'custom',
        customType: 'reme-memory',
        content: 'remember safely',
        display: false,
      },
    ];
    expect(firstContext).toEqual({ messages: expectedMessages });
    expect(secondContext).toEqual({ messages: expectedMessages });
    expect(persistedMessages).toEqual([
      { role: 'user', content: 'persisted' },
      { role: 'custom', customType: 'reme-memory', content: 'stale copy', display: false },
    ]);
    expect(executions[0]?.args.join(' ')).not.toContain('ordinary prompt');
    expect((executions[0]?.options as { input: string }).input).toContain(
      '"session_id":"documented-session-id"',
    );
    expect(executions[0]?.options).toMatchObject({ input: expect.stringContaining('ordinary prompt') });
  });

  test('captures only the latest finalized assistant after agent settlement', async () => {
    const registrations: Array<Map<string, Function>> = [];
    const payloads: Array<Record<string, unknown>> = [];
    const createPi = () => {
      const handlers = new Map<string, Function>();
      registrations.push(handlers);
      return {
        on: (name: string, handler: Function) => handlers.set(name, handler),
        exec: async (_command: string, _args: string[], options: { input: string }) => {
          payloads.push(JSON.parse(options.input));
          return { stdout: '{}', stderr: '', code: 0 };
        },
      };
    };
    registerReMeMemory(createPi() as any);
    registerReMeMemory(createPi() as any);

    await registrations[0]!.get('before_agent_start')!(
      { prompt: 'first', systemPrompt: 'system' },
      { cwd: '/work/project' },
    );
    await registrations[1]!.get('before_agent_start')!(
      { prompt: 'second', systemPrompt: 'system' },
      { cwd: '/work/project' },
    );
    expect(payloads[0]?.session_id).not.toBe('pi-session');
    expect(payloads[0]?.session_id).not.toBe(payloads[1]?.session_id);

    const firstAssistantMessage = {
      message: {
        role: 'assistant',
        content: [{ type: 'text', text: 'intermediate tool plan' }],
      },
    };
    const toolMessage = {
      message: { role: 'tool', content: [{ type: 'text', text: 'tool result' }] },
    };
    const finalAssistantMessage = {
      message: {
        role: 'assistant',
        content: [{ type: 'text', text: 'finalized answer' }],
      },
    };
    const context = {
      cwd: '/work/project',
    };
    const messageEndResult = await registrations[0]!.get('message_end')!(firstAssistantMessage, context);
    await registrations[0]!.get('message_end')!(toolMessage, context);
    await registrations[0]!.get('message_end')!(finalAssistantMessage, context);
    expect(messageEndResult).toBeUndefined();
    expect(payloads).toHaveLength(2);

    await registrations[0]!.get('agent_settled')!({}, context);
    expect(payloads[2]).toMatchObject({
      event: 'Stop',
      session_id: payloads[0]?.session_id,
      last_assistant_message: 'finalized answer',
    });
    expect(payloads).toHaveLength(3);

    await registrations[0]!.get('agent_settled')!({}, context);
    await registrations[0]!.get('session_shutdown')!({}, context);
    expect(payloads).toHaveLength(3);
  });
});
