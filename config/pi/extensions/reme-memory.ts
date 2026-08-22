import { randomUUID } from 'node:crypto';
import { homedir } from 'node:os';
import { join } from 'node:path';

import type { ExtensionAPI } from '@earendil-works/pi-coding-agent';

type PiContext = {
  cwd?: string;
  sessionManager?: { getSessionId?: () => unknown };
};
type ExecutionResult = { stdout?: string };
type PiMessage = { role?: unknown; customType?: unknown; content?: unknown; display?: unknown };

const MEMORY_MESSAGE_TYPE = 'reme-memory';

function bridgePath(): string {
  return join(process.env.HOME || homedir(), '.config', 'agents', 'reme-memory-bridge.ts');
}

function textContent(content: unknown): string {
  if (typeof content === 'string') return content.trim();
  if (!Array.isArray(content)) return '';
  return content
    .filter(
      (part): part is { type: string; text: string } =>
        !!part &&
        typeof part === 'object' &&
        (part as Record<string, unknown>).type === 'text' &&
        typeof (part as Record<string, unknown>).text === 'string',
    )
    .map((part) => part.text.trim())
    .filter(Boolean)
    .join('\n');
}

export default function registerReMeMemory(pi: ExtensionAPI) {
  let cachedContext = '';
  let pendingUserText = '';
  let latestAssistantText = '';
  const fallbackSessionID = `pi-${process.pid}-${randomUUID()}`;

  function sessionID(context: PiContext): string {
    const managedSessionID = context.sessionManager?.getSessionId?.();
    return typeof managedSessionID === 'string' && managedSessionID
      ? managedSessionID
      : fallbackSessionID;
  }

  async function invokeBridge(payload: Record<string, unknown>): Promise<Record<string, unknown>> {
    try {
      const result = (await pi.exec('bun', [bridgePath()], {
        input: JSON.stringify(payload),
      })) as ExecutionResult;
      if (!result.stdout || result.stdout.length > 16_000) return {};
      const value: unknown = JSON.parse(result.stdout);
      return value && typeof value === 'object' && !Array.isArray(value)
        ? (value as Record<string, unknown>)
        : {};
    } catch {
      return {};
    }
  }

  pi.on(
    'before_agent_start',
    async (event: { prompt?: unknown; systemPrompt?: unknown }, context: PiContext) => {
      const prompt = typeof event.prompt === 'string' ? event.prompt.trim() : '';
      cachedContext = '';
      pendingUserText = '';
      latestAssistantText = '';
      pendingUserText = prompt;
      const output = await invokeBridge({
        host: 'pi',
        event: 'UserPromptSubmit',
        session_id: sessionID(context),
        cwd: context.cwd || process.cwd(),
        prompt,
      });
      cachedContext = typeof output.additionalContext === 'string' ? output.additionalContext : '';
      return typeof event.systemPrompt === 'string'
        ? { systemPrompt: event.systemPrompt }
        : undefined;
    },
  );

  pi.on('context', async (event: { messages?: PiMessage[] }) => {
    if (!cachedContext || !Array.isArray(event.messages)) return undefined;
    const messages = event.messages.filter(
      (message) => message.customType !== MEMORY_MESSAGE_TYPE,
    );
    return {
      messages: [
        ...messages,
        {
          role: 'custom',
          customType: MEMORY_MESSAGE_TYPE,
          content: cachedContext,
          display: false,
        },
      ],
    };
  });

  pi.on(
    'message_end',
    async (event: { message?: { role?: unknown; content?: unknown } }) => {
      const message = event.message;
      if (!message || message.role !== 'assistant' || !pendingUserText) return;
      const assistantText = textContent(message.content);
      if (!assistantText) return;
      latestAssistantText = assistantText;
    },
  );

  pi.on(
    'agent_settled',
    async (_event: unknown, context: PiContext) => {
      const assistantText = latestAssistantText;
      const hasCompletedTurn = Boolean(pendingUserText && assistantText);
      pendingUserText = '';
      latestAssistantText = '';
      if (!hasCompletedTurn) return;
      await invokeBridge({
        host: 'pi',
        event: 'Stop',
        session_id: sessionID(context),
        cwd: context.cwd || process.cwd(),
        last_assistant_message: assistantText,
      });
    },
  );

  pi.on('session_shutdown', async () => {
    cachedContext = '';
    pendingUserText = '';
    latestAssistantText = '';
  });
}
