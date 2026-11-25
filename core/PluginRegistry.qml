pragma Singleton

import QtQml
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import "./plugin-catalog.mjs" as Catalog

// A varredura de plugins dentro da shell (0.512). O outro lado desta
// mesma moeda e cli/lib/plugins.js: os dois leem os mesmos arquivos e
// chamam o mesmo buildCatalog, entao um teste em node afirma algo sobre o
// que a shell enxerga de verdade.
//
// Medido antes de escrever (os dois com `qs`):
//   1. Qt.labs.folderlistmodel lista pastas de dentro da shell.
//   2. FileView { blockLoading: true }, criado em tempo de execucao, le um
//      arquivo de forma SINCRONA - da para montar o catalogo inteiro
//      dentro de uma funcao, sem cascata de callbacks.
//
// So a listagem de pastas e assincrona, e e por isso que o plugin embutido
// (a propria shell) entra na primeira passada e os instalados entram na
// segunda, quando o FolderListModel fica pronto. Quem desenha reage a
// `catalog` mudar, entao a diferenca e um quadro, nao um caso especial.
QtObject {
    id: root

    // O catalogo inteiro: plugins, modules, faces e problemas. Tudo que o
    // resto da shell pergunta passa pelas funcoes abaixo, nunca por disco.
    property var catalog: Catalog.emptyCatalog()

    readonly property Component readerComponent: Component {
        FileView { blockLoading: true }
    }

    readonly property FolderListModel installed: FolderListModel {
        folder: "file://" + Paths.pluginDir
        showFiles: false
        showDirs: true
        showDotAndDotDot: false
        sortField: FolderListModel.Name
        onStatusChanged: if (status === FolderListModel.Ready) root.rescan()
        onCountChanged: root.rescan()
    }

    // `missing` nao e a mesma coisa que `error`: uma pasta sem plugin.json
    // nenhum nao e um plugin quebrado, e so uma pasta - avisar sobre ela
    // encheria o log de ruido por cada coisa que o usuario deixou ali. Um
    // plugin.json que EXISTE e nao e JSON valido, esse sim e problema.
    function readJson(path) {
        const reader = readerComponent.createObject(root, { path: path });
        if (!reader) return { value: null, error: null, missing: true };
        let text = "";
        try {
            text = reader.text();
        } catch (error) {
            text = "";
        }
        reader.destroy();
        if (!text || text.length === 0) return { value: null, error: null, missing: true };
        try {
            return { value: JSON.parse(text), error: null, missing: false };
        } catch (error) {
            return { value: null, error: path + ": " + error, missing: false };
        }
    }

    // Um plugin, do disco para o formato que o catalogo espera. Identico
    // ao readPlugin de cli/lib/plugins.js de proposito.
    function readPlugin(pluginRoot, builtin) {
        const manifest = readJson(pluginRoot + "/plugin.json");
        const found = {
            root: pluginRoot,
            builtin: builtin,
            id: pluginRoot.split("/").pop(),
            manifest: manifest.value,
            manifestError: manifest.error,
            modules: [],
            faces: [],
        };
        found.missing = manifest.missing === true;
        if (!manifest.value) return found;
        for (const dir of (manifest.value.modules ?? [])) {
            const meta = readJson(pluginRoot + "/" + dir + "/meta.json");
            found.modules.push({ dir: dir, meta: meta.value, error: meta.error });
        }
        for (const dir of (manifest.value.faces ?? [])) {
            const meta = readJson(pluginRoot + "/" + dir + "/meta.json");
            found.faces.push({ dir: dir, meta: meta.value, error: meta.error });
        }
        return found;
    }

    // A unica listagem de diretorio da varredura inteira. Dali em diante o
    // manifesto diz onde esta cada coisa.
    function rescan() {
        const scanned = [readPlugin(Quickshell.shellDir, true)];
        // Pegadinha medida aqui: com uma pasta que nao existe, o
        // FolderListModel nao fica vazio - ele continua listando o
        // diretorio corrente, e a shell "achou" um plugin para cada pasta
        // do proprio repositorio. Confere-se a pasta que ele de fato
        // abriu antes de acreditar no que ele lista.
        const expected = "file://" + Paths.pluginDir;
        if (installed.folder.toString() === expected) {
            for (let i = 0; i < installed.count; i++) {
                const name = installed.get(i, "fileName");
                const candidate = readPlugin(Paths.pluginDir + "/" + name, false);
                if (candidate.missing) continue; // pasta sem plugin.json: nao e plugin
                scanned.push(candidate);
            }
        }
        root.catalog = Catalog.buildCatalog(scanned);
        for (const problem of root.catalog.problems)
            console.warn("vtnc: plugin:", problem);
    }

    Component.onCompleted: root.rescan()

    // ---- o que o resto da shell pergunta ----

    function plugins() { return root.catalog.plugins; }
    function problems() { return root.catalog.problems; }
    function moduleIds() { return Catalog.moduleIds(root.catalog); }
    function moduleMeta(moduleId) { return Catalog.moduleMeta(root.catalog, moduleId); }
    function moduleUrl(moduleId) { return Catalog.moduleUrl(root.catalog, moduleId); }
    function facesOf(moduleId) { return Catalog.facesOf(root.catalog, moduleId); }
    function faceMeta(moduleId, face) { return Catalog.faceMeta(root.catalog, moduleId, face); }
    function defaultFaceOf(moduleId) { return Catalog.defaultFaceOf(root.catalog, moduleId); }
    function resolvedFaceUrl(moduleId, face) { return Catalog.resolvedFaceUrl(root.catalog, moduleId, face); }
    function providesOf(moduleId) { return Catalog.providesOf(root.catalog, moduleId); }
    function optionSchemaOf(moduleId, face) { return Catalog.optionSchemaOf(root.catalog, moduleId, face); }
    function placeableModules() { return Catalog.placeableModules(root.catalog); }
    function isPlaceableModule(moduleId) { return Catalog.isPlaceableModule(root.catalog, moduleId); }
}
