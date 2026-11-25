// O catalogo: o que a shell sabe depois de varrer os plugins (0.512).
//
// Substitui o core/widget-registry.mjs da 0.509, que importava cada meta a
// mao. A diferenca que importa nao e de estilo: ali a lista de quem existe
// era CODIGO, escrito dentro da shell, e por isso nada de fora dela podia
// entrar. Aqui a lista e DADO, montado em tempo de execucao a partir do
// disco, e o vtnc entra por ele como qualquer outro plugin.
//
// Este arquivo nao le disco nem conhece Qt. Ele recebe o que o scanner
// achou - um por plugin - e devolve o catalogo com tudo ja resolvido. Quem
// le disco: core/PluginRegistry.qml na shell, cli/lib/plugins.js no node.
//
// O formato que o scanner entrega:
//   { root, manifest, manifestError, modules: [{ dir, meta, error }],
//     faces: [{ dir, meta, error }] }

import {
    apiCompatible,
    validateManifest,
    validateModuleMeta,
    validateFaceMeta,
    PLUGIN_API_MIN,
    PLUGIN_API_CURRENT,
} from "./plugin-manifest.mjs";

// `options` nao entra no `provides` de ninguem: e o canal que o vtnc da a
// toda face (decisao 3.4), nao algo que este ou aquele module inventou.
export const FRAMEWORK_PROPERTIES = ["options"];

function url(root, dir, component) {
    const base = dir ? root + "/" + dir : root;
    return "file://" + base + "/" + component;
}

export function emptyCatalog() {
    return { plugins: [], modules: [], faces: [], problems: [] };
}

// Monta o catalogo. Nada aqui lanca excecao: um plugin quebrado vira um
// problema na lista e os outros continuam carregando (decisao 3.4d, a
// mesma regra que ja valia para uma declaracao de opcao invalida - um meta
// mal escrito de terceiro nao pode tirar a shell do ar).
export function buildCatalog(scanned) {
    const catalog = emptyCatalog();

    for (const found of scanned) {
        const manifest = found.manifest;
        const entry = {
            id: manifest && typeof manifest.id === "string" ? manifest.id : (found.id ?? "?"),
            root: found.root,
            version: manifest ? manifest.version : null,
            pluginApi: manifest ? manifest.pluginApi : null,
            author: manifest ? manifest.author : null,
            description: manifest ? manifest.description ?? "" : "",
            builtin: found.builtin === true,
            loaded: false,
            compatible: false,
            problems: [],
        };
        catalog.plugins.push(entry);

        if (found.manifestError) {
            entry.problems.push(found.manifestError);
            catalog.problems.push(`${entry.id}: ${found.manifestError}`);
            continue;
        }
        const check = validateManifest(manifest);
        if (!check.ok) {
            for (const error of check.errors) {
                entry.problems.push(error);
                catalog.problems.push(`${entry.id}: ${error}`);
            }
            continue;
        }

        // A faixa de API e recusa por FAIXA, nao por erro de carga: o
        // plugin continua listado, com a versao e o nivel que pediu, para
        // o usuario entender por que ele nao aparece.
        entry.compatible = apiCompatible(manifest.pluginApi);
        if (!entry.compatible) {
            entry.problems.push(
                `pluginApi ${manifest.pluginApi} fora da faixa que esta shell suporta (${PLUGIN_API_MIN}-${PLUGIN_API_CURRENT})`);
            continue;
        }

        for (const candidate of (found.modules ?? [])) {
            const problem = moduleProblem(entry, candidate);
            if (problem) {
                entry.problems.push(problem);
                catalog.problems.push(`${entry.id}: ${problem}`);
                continue;
            }
            catalog.modules.push({
                id: entry.id + "." + candidate.meta.module,
                pluginId: entry.id,
                // `title` sobe do meta porque quem desenha menu le a
                // entrada do catalogo, nao o meta cru. Deixar so em
                // `meta` ja custou um chip sem rotulo: o QML pegou
                // `undefined`, nao quebrou, e o controle simplesmente
                // nao existiu na tela.
                title: candidate.meta.title,
                dir: candidate.dir,
                meta: candidate.meta,
                componentUrl: url(entry.root, candidate.dir, candidate.meta.component),
            });
        }

        for (const candidate of (found.faces ?? [])) {
            const problem = faceProblem(entry, candidate);
            if (problem) {
                entry.problems.push(problem);
                catalog.problems.push(`${entry.id}: ${problem}`);
                continue;
            }
            catalog.faces.push({
                face: candidate.meta.face,
                moduleId: candidate.meta.module,
                pluginId: entry.id,
                title: candidate.meta.title,
                options: candidate.meta.options ?? [],
                dir: candidate.dir,
                meta: candidate.meta,
                componentUrl: url(entry.root, candidate.dir, candidate.meta.component),
            });
        }

        entry.loaded = true;
    }

    // Uma face pode vestir o module de outro plugin, entao so da para
    // conferir se o alvo existe depois que todos foram lidos.
    catalog.faces = catalog.faces.filter((face) => {
        if (moduleEntry(catalog, face.moduleId)) return true;
        const problem = `a face ${face.pluginId}/${face.face} veste o module ${face.moduleId}, que nao existe`;
        catalog.problems.push(problem);
        const owner = catalog.plugins.find((plugin) => plugin.id === face.pluginId);
        if (owner) owner.problems.push(problem);
        return false;
    });

    return catalog;
}

function moduleProblem(plugin, found) {
    if (found.error) return `${found.dir}: ${found.error}`;
    const check = validateModuleMeta(found.meta);
    if (!check.ok) return `${found.dir}: ${check.errors.join("; ")}`;
    return null;
}

function faceProblem(plugin, found) {
    if (found.error) return `${found.dir}: ${found.error}`;
    const check = validateFaceMeta(found.meta);
    if (!check.ok) return `${found.dir}: ${check.errors.join("; ")}`;
    return null;
}

// ---- as consultas, todas sobre um catalogo ja montado ----

export function moduleEntry(catalog, moduleId) {
    return catalog.modules.find((entry) => entry.id === moduleId) ?? null;
}

export function moduleMeta(catalog, moduleId) {
    const entry = moduleEntry(catalog, moduleId);
    return entry ? entry.meta : null;
}

export function moduleIds(catalog) {
    return catalog.modules.map((entry) => entry.id);
}

export function moduleUrl(catalog, moduleId) {
    const entry = moduleEntry(catalog, moduleId);
    return entry ? entry.componentUrl : "";
}

// Quais faces um module tem. Derivado do `module` declarado por cada face
// (decisao 3.5), nunca de uma lista no meta do module: a lista escrita duas
// vezes era justamente o que podia discordar em silencio.
export function facesOf(catalog, moduleId) {
    return catalog.faces.filter((entry) => entry.moduleId === moduleId);
}

export function faceEntry(catalog, moduleId, face) {
    return catalog.faces.find((entry) => entry.moduleId === moduleId && entry.face === face) ?? null;
}

export function faceMeta(catalog, moduleId, face) {
    const entry = faceEntry(catalog, moduleId, face);
    return entry ? entry.meta : null;
}

export function defaultFaceOf(catalog, moduleId) {
    const meta = moduleMeta(catalog, moduleId);
    return meta ? meta.defaultFace : null;
}

export function faceUrl(catalog, moduleId, face) {
    const entry = faceEntry(catalog, moduleId, face);
    return entry ? entry.componentUrl : "";
}

// A face que vale: a pedida, se existir neste module, senao a padrao dele.
// E o que o QML do module chama, para nao repetir essa queda em cada um.
export function resolvedFaceUrl(catalog, moduleId, face) {
    return faceUrl(catalog, moduleId, face) || faceUrl(catalog, moduleId, defaultFaceOf(catalog, moduleId));
}

export function providesOf(catalog, moduleId) {
    const meta = moduleMeta(catalog, moduleId);
    return meta && meta.provides ? meta.provides : [];
}

export function optionSchemaOf(catalog, moduleId, face) {
    const meta = faceMeta(catalog, moduleId, face);
    return meta && meta.options ? meta.options : [];
}

// O que o editor de Pages pode oferecer para acrescentar. Antes era uma
// lista escrita a mao em core/widget-catalog.mjs; agora cada module diz de
// si mesmo se da para coloca-lo numa page, e com que tamanho.
export function placeableModules(catalog) {
    return catalog.modules
        .filter((entry) => entry.meta.placeable === true)
        .map((entry) => ({ module: entry.id, title: entry.meta.title, defaultCell: entry.meta.defaultCell }));
}

export function isPlaceableModule(catalog, moduleId) {
    const meta = moduleMeta(catalog, moduleId);
    return meta ? meta.placeable === true : false;
}

export function servicesOf(catalog, moduleId) {
    const meta = moduleMeta(catalog, moduleId);
    return meta && meta.services ? meta.services : [];
}
