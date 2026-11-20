import { join } from "node:path";
import { homedir } from "node:os";

export function configDir() {
    return process.env.VTNC_CONFIG_DIR || join(homedir(), ".config", "vtnc");
}

export function configFile() {
    return join(configDir(), "config.json");
}
