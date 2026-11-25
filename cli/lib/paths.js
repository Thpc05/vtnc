import { join } from "node:path";
import { homedir } from "node:os";

export function configDir() {
    return process.env.VTNC_CONFIG_DIR || join(homedir(), ".config", "vtnc");
}

export function configFile() {
    return join(configDir(), "config.json");
}

// Onde moram os plugins instalados (decisao do Theo em 2026-11-24): em
// ~/.local/share, nao em ~/.config. Plugin e codigo baixado, nao
// configuracao escrita pelo usuario - quem faz backup ou git da propria
// config nao leva codigo de terceiro junto.
export function pluginDir() {
    const override = process.env.VTNC_PLUGIN_DIR;
    if (override) return override;
    const dataHome = process.env.XDG_DATA_HOME || join(homedir(), ".local", "share");
    return join(dataHome, "vtnc", "plugins");
}

// A raiz do plugin embutido: a propria pasta da shell. Ele nao e um caso
// especial do carregador - e so mais uma raiz na lista que o scanner
// recebe (ver core/plugin-catalog.mjs).
export function builtinPluginRoot() {
    return process.env.VTNC_BUILTIN_ROOT || new URL("../..", import.meta.url).pathname.replace(/\/$/, "");
}
