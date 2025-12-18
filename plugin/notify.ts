import type { Plugin } from "@opencode-ai/plugin";
import * as fs from "node:fs";
import * as path from "node:path";

const SOUNDS = {
  success: "/System/Library/Sounds/Glass.aiff",
  error: "/System/Library/Sounds/Basso.aiff",
  complete: "/System/Library/Sounds/Ping.aiff",
};

type Platform = "macos" | "linux" | "unknown";

interface NotificationConfig {
  enabled: boolean;
  events: {
    swarmComplete: boolean;
    swarmAbort: boolean;
    sessionIdle: boolean;
  };
  sound: boolean;
  debug: boolean;
}

const DEFAULT_CONFIG: NotificationConfig = {
  enabled: true,
  events: {
    swarmComplete: true,
    swarmAbort: true,
    sessionIdle: true,
  },
  sound: true,
  debug: false,
};

function getConfigPath(): string {
  const configDir = process.env.OPENCODE_CONFIG_DIR || path.join(process.env.HOME || "~", ".config", "opencode");
  return path.join(configDir, "notifications.local.json");
}

function loadConfig(): NotificationConfig {
  try {
    const configPath = getConfigPath();
    if (fs.existsSync(configPath)) {
      const data = fs.readFileSync(configPath, "utf-8");
      return { ...DEFAULT_CONFIG, ...JSON.parse(data) };
    }
  } catch (error) {
    debugLog("Failed to load notification config:", error);
  }
  return DEFAULT_CONFIG;
}

let config = loadConfig();

function debugLog(...args: unknown[]): void {
  if (config.debug) {
    console.error("[notify]", ...args);
  }
}

function getPlatform(): Platform {
  return process.platform === "darwin" ? "macos" : 
         process.platform === "linux" ? "linux" : "unknown";
}

function isSSHSession(): boolean {
  return !!(process.env.SSH_CONNECTION || process.env.SSH_CLIENT);
}

function isVSCodeTerminal(): boolean {
  return !!process.env.TERM_PROGRAM && process.env.TERM_PROGRAM === "vscode";
}

function sendOSCNotification(title: string, message: string): void {
  // VSCode terminal doesn't support OSC notification sequences
  if (isVSCodeTerminal()) {
    console.log(`[${title}] ${message}`);
    return;
  }
  
  // OSC 777 (iTerm2 proprietary) and OSC 9 (xterm-style)
  process.stdout.write(`\x1b]777;notify;${title};${message}\x07`);
  process.stdout.write(`\x1b]9;${title}: ${message}\x07`);
}

async function sendLocalNotification(title: string, message: string, platform: Platform): Promise<void> {
  try {
    if (platform === "macos") {
      const script = `display notification "${message}" with title "${title}"`;
      const proc = Bun.spawn(["osascript", "-e", script], { stdout: "pipe", stderr: "pipe" });
      const exitCode = await proc.exited;
      if (exitCode !== 0) {
        debugLog("osascript failed with exit code:", exitCode);
      }
    } else if (platform === "linux") {
      const proc = Bun.spawn(["notify-send", title, message], { stdout: "pipe", stderr: "pipe" });
      const exitCode = await proc.exited;
      if (exitCode !== 0) {
        debugLog("notify-send failed with exit code:", exitCode);
      }
    }
  } catch (error) {
    debugLog("Failed to send local notification:", error);
  }
}

async function notify(title: string, message: string): Promise<void> {
  if (!config.enabled) {
    debugLog("Notifications disabled, skipping:", title);
    return;
  }
  
  debugLog("Sending notification:", title, message);
  
  if (isSSHSession()) {
    sendOSCNotification(title, message);
  } else {
    await sendLocalNotification(title, message, getPlatform());
  }
}

async function playSound(sound: keyof typeof SOUNDS): Promise<void> {
  if (!config.enabled || !config.sound) {
    debugLog("Sound disabled, skipping:", sound);
    return;
  }
  
  if (isSSHSession()) return;
  if (getPlatform() !== "macos") return;
  
  try {
    const proc = Bun.spawn(["afplay", SOUNDS[sound]], { stdout: "pipe", stderr: "pipe" });
    const exitCode = await proc.exited;
    if (exitCode !== 0) {
      debugLog("afplay failed with exit code:", exitCode);
    }
  } catch (error) {
    debugLog("Failed to play sound:", error);
  }
}

export const NotifyPlugin: Plugin = async () => {
  config = loadConfig();
  debugLog("Notification config loaded:", config);
  
  return {
    event: async ({ event }) => {
      if (event.type === "session.idle" && config.events.sessionIdle) {
        await playSound("complete");
      }
    },

    "tool.execute.after": async (toolInput, output) => {
      if (toolInput.tool === "swarm_finalize" && config.events.swarmComplete) {
        const result = JSON.parse(output.output ?? "{}");
        if (result.success) {
          await notify("Swarm Complete", "All tasks finished successfully");
          await playSound("success");
        }
      }

      if (toolInput.tool === "swarm_abort" && config.events.swarmAbort) {
        await notify("Swarm Aborted", "Swarm was aborted or failed");
        await playSound("error");
      }
    },
  };
};

export default NotifyPlugin;
