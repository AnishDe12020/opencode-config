import type { Plugin } from "@opencode-ai/plugin";

const SOUNDS = {
  success: "/System/Library/Sounds/Glass.aiff",
  error: "/System/Library/Sounds/Basso.aiff",
  complete: "/System/Library/Sounds/Ping.aiff",
};

type Platform = "macos" | "linux" | "unknown";

function getPlatform(): Platform {
  return process.platform === "darwin" ? "macos" : 
         process.platform === "linux" ? "linux" : "unknown";
}

function isSSHSession(): boolean {
  return !!(process.env.SSH_CONNECTION || process.env.SSH_CLIENT);
}

function sendOSCNotification(title: string, message: string): void {
  process.stdout.write(`\x1b]777;notify;${title};${message}\x07`);
  process.stdout.write(`\x1b]9;${title}: ${message}\x07`);
}

async function sendLocalNotification(title: string, message: string, platform: Platform): Promise<void> {
  try {
    if (platform === "macos") {
      const script = `display notification "${message}" with title "${title}"`;
      Bun.spawn(["osascript", "-e", script], { stdout: "ignore", stderr: "ignore" });
    } else if (platform === "linux") {
      Bun.spawn(["notify-send", title, message], { stdout: "ignore", stderr: "ignore" });
    }
  } catch {}
}

async function notify(title: string, message: string): Promise<void> {
  if (isSSHSession()) {
    sendOSCNotification(title, message);
  } else {
    await sendLocalNotification(title, message, getPlatform());
  }
}

async function playSound(sound: keyof typeof SOUNDS): Promise<void> {
  if (isSSHSession()) return;
  if (getPlatform() !== "macos") return;
  
  try {
    Bun.spawn(["afplay", SOUNDS[sound]], { stdout: "ignore", stderr: "ignore" });
  } catch {}
}

export const NotifyPlugin: Plugin = async () => {
  return {
    event: async ({ event }) => {
      if (event.type === "session.idle") {
        await playSound("complete");
      }
    },

    "tool.execute.after": async (toolInput, output) => {
      if (toolInput.tool === "swarm_finalize") {
        const result = JSON.parse(output.output ?? "{}");
        if (result.success) {
          await notify("Swarm Complete", "All tasks finished successfully");
          await playSound("success");
        }
      }

      if (toolInput.tool === "swarm_abort") {
        await notify("Swarm Aborted", "Swarm was aborted or failed");
        await playSound("error");
      }
    },
  };
};

export default NotifyPlugin;
