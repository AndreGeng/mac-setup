/** Reports Pi agent status to Workmux when Workmux is available. */
import type { ExtensionAPI } from '@earendil-works/pi-coding-agent';

export default function (pi: ExtensionAPI) {
  function setStatus(status: string) {
    pi.exec('workmux', ['set-window-status', status]).catch(() => {});
  }

  pi.on('agent_start', async () => setStatus('working'));
  pi.on('agent_end', async () => setStatus('done'));
}
