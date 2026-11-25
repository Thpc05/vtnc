// A varredura do lado node: le o disco e entrega ao core/plugin-catalog.mjs
// exatamente o mesmo formato que o core/PluginRegistry.qml entrega na
// shell. Os dois leem os mesmos arquivos e chamam o mesmo buildCatalog, e
// e por isso que um teste em node pode afirmar algo sobre o que a shell
// vai enxergar.

import { readFileSync, readdirSync, existsSync, statSync } from "node:fs";
import { join } from "node:path";

import { buildCatalog } from "../../core/plugin-catalog.mjs";
import { pluginDir, builtinPluginRoot } from "./paths.js";

function readJson(path) {
    try {
        return { value: JSON.parse(readFileSync(path, "utf8")), error: null };
    } catch (error) {
        return { value: null, error: `${path.split("/").slice(-2).join("/")}: ${error.message}` };
    }
}

// Um plugin, do disco para o formato do catalogo. `builtin` so marca quem
// e a propria shell na listagem; o caminho do codigo e o mesmo.
export function readPlugin(root, builtin = false) {
    const manifest = readJson(join(root, "plugin.json"));
    const found = {
        root,
        builtin,
        id: root.split("/").pop(),
        manifest: manifest.value,
        manifestError: manifest.error,
        modules: [],
        faces: [],
    };
    if (!manifest.value) return found;

    for (const dir of manifest.value.modules ?? []) {
        const meta = readJson(join(root, dir, "meta.json"));
        found.modules.push({ dir, meta: meta.value, error: meta.error });
    }
    for (const dir of manifest.value.faces ?? []) {
        const meta = readJson(join(root, dir, "meta.json"));
        found.faces.push({ dir, meta: meta.value, error: meta.error });
    }
    return found;
}

// As raizes de plugin que existem agora: a shell em primeiro lugar, depois
// cada pasta instalada. Esta e a UNICA listagem de diretorio da varredura -
// dali em diante tudo e leitura de arquivo, guiada pelo manifesto.
export function pluginRoots() {
    const roots = [{ root: builtinPluginRoot(), builtin: true }];
    const dir = pluginDir();
    if (existsSync(dir)) {
        for (const name of readdirSync(dir).sort()) {
            const root = join(dir, name);
            if (statSync(root).isDirectory() && existsSync(join(root, "plugin.json")))
                roots.push({ root, builtin: false });
        }
    }
    return roots;
}

export function scanPlugins() {
    return pluginRoots().map((entry) => readPlugin(entry.root, entry.builtin));
}

export function loadCatalog() {
    return buildCatalog(scanPlugins());
}
