---
description: test notification system (local and ssh)
---

You are testing the OpenCode notification system.

## Task

Execute the notification test plugin to verify:
1. Platform detection (macOS/Linux/SSH)
2. Notification delivery
3. Sound playback (if applicable)
4. Terminal compatibility (for SSH)

## Steps

1. Run the test by executing this TypeScript code using bash with bun:

```typescript
// test-notifications.ts
import * as fs from "node:fs";
import * as path from "node:path";

const SOUNDS = {
  success: "/System/Library/Sounds/Glass.aiff",
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

function isVSCodeTerminal(): boolean {
  return !!process.env.TERM_PROGRAM && process.env.TERM_PROGRAM === "vscode";
}

async function testNotification(): Promise<void> {
  const platform = getPlatform();
  const isSSH = isSSHSession();
  const isVSCode = isVSCodeTerminal();
  
  console.log("=== Notification System Test ===\n");
  console.log("Platform:", platform);
  console.log("SSH Session:", isSSH);
  console.log("VSCode Terminal:", isVSCode);
  console.log("Terminal:", process.env.TERM_PROGRAM || "unknown");
  console.log();

  if (isSSH) {
    console.log("Testing OSC notification sequences...");
    if (isVSCode) {
      console.log("[Test Notification] This is a test from VSCode terminal");
    } else {
      process.stdout.write(`\x1b]777;notify;Test Notification;This is a test notification via OSC\x07`);
      process.stdout.write(`\x1b]9;Test Notification: This is a test notification via OSC\x07`);
      console.log("OSC sequences sent. Check your terminal for notification.");
    }
  } else {
    console.log("Testing local notifications...");
    
    if (platform === "macos") {
      const script = `display notification "This is a test notification" with title "OpenCode Test"`;
      const proc = Bun.spawn(["osascript", "-e", script], { stdout: "pipe", stderr: "pipe" });
      const exitCode = await proc.exited;
      
      if (exitCode === 0) {
        console.log("✓ macOS notification sent successfully");
        
        console.log("\nTesting sound playback...");
        const soundProc = Bun.spawn(["afplay", SOUNDS.complete], { stdout: "pipe", stderr: "pipe" });
        const soundExit = await soundProc.exited;
        
        if (soundExit === 0) {
          console.log("✓ Sound played successfully");
        } else {
          console.log("✗ Sound playback failed");
        }
      } else {
        console.log("✗ macOS notification failed");
      }
    } else if (platform === "linux") {
      const proc = Bun.spawn(["notify-send", "OpenCode Test", "This is a test notification"], { stdout: "pipe", stderr: "pipe" });
      const exitCode = await proc.exited;
      
      if (exitCode === 0) {
        console.log("✓ Linux notification sent successfully");
      } else {
        console.log("✗ Linux notification failed (is notify-send installed?)");
      }
    } else {
      console.log("✗ Unsupported platform");
    }
  }
  
  console.log("\n=== Test Complete ===");
  console.log("\nIf you didn't see a notification:");
  console.log("- macOS: Check System Settings → Notifications → Script Editor");
  console.log("- Linux: Install notify-send (libnotify-bin, libnotify, etc.)");
  console.log("- SSH: Verify terminal supports OSC (iTerm2, kitty, Ghostty, WezTerm, Alacritty)");
  console.log("- VSCode: Use external terminal instead (OSC not supported)");
}

testNotification().catch(console.error);
```

2. Save the code to a temporary file and execute it with `bun run`

3. Report the results to the user:
   - Whether notifications appeared
   - Platform and environment details
   - Any errors encountered
   - Troubleshooting suggestions if failed

## Important

- Do NOT ask for confirmation, just run the test
- Show the full output to the user
- Provide specific troubleshooting steps if test fails
