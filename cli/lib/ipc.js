import { execFileSync } from "node:child_process";

// Talks to the running shell over Quickshell's own IPC (decision 1b.1).
// Used for `call`, `get` and `list` — never for `set`, which writes the
// config file directly (store.js) and never touches the running process.
export function ipcCall(shellRoot, target, fn, args) {
    try {
        const out = execFileSync("qs", ["ipc", "-p", shellRoot, "call", target, fn, ...args], {
            encoding: "utf8",
        });
        return out.trim();
    } catch (e) {
        const stderr = e.stderr ? e.stderr.toString().trim() : e.message;
        throw new Error(`vtnc: couldn't reach the running shell (${stderr})`);
    }
}
