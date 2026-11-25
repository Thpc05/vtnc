// Camada 1 da 0.512: o manifesto, a varredura e o catalogo.
//
// O teste que importa aqui e o que monta um plugin INTEIRO numa pasta
// descartavel e manda a shell varrer: e a unica forma de provar que o
// mecanismo nao e so para o vtnc. O mesmo plugin descartavel serve para
// provar a recusa por faixa de API, que e a promessa que mais importa
// quando a shell atualizar e o plugin de terceiro nao acompanhar.

import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync, readdirSync, existsSync, mkdirSync, writeFileSync, rmSync, mkdtempSync } from "node:fs";
import { join, dirname } from "node:path";
import { tmpdir } from "node:os";
import { fileURLToPath } from "node:url";

import {
    PLUGIN_API_MIN, PLUGIN_API_CURRENT, apiCompatible,
    validateManifest, validateModuleMeta, validateFaceMeta,
} from "../../core/plugin-manifest.mjs";
import {
    buildCatalog, moduleMeta, moduleEntry, facesOf, faceMeta, defaultFaceOf,
    resolvedFaceUrl, moduleUrl, providesOf, optionSchemaOf, placeableModules,
    isPlaceableModule, moduleIds, FRAMEWORK_PROPERTIES,
} from "../../core/plugin-catalog.mjs";
import { readPlugin, scanPlugins, loadCatalog } from "../../cli/lib/plugins.js";

const repoRoot = join(dirname(fileURLToPath(import.meta.url)), "..", "..");

// ---- o manifesto ----

const GOOD = { id: "shapes", version: "1.0.0", pluginApi: 1, author: "user8", modules: [], faces: [] };

test("um manifesto bom passa, e cada campo errado reprova por si", () => {
    assert.equal(validateManifest(GOOD).ok, true);
    const cases = [
        [{ id: "Shapes" }, /id/],
        [{ id: "user8.shapes" }, /sem ponto/],
        [{ version: "1.0" }, /semver/],
        [{ pluginApi: "1" }, /inteiro/],
        [{ author: "" }, /author/],
        [{ modules: "modules/clock" }, /lista/],
        [{ modules: ["/etc/passwd"] }, /absoluto/],
        [{ modules: ["../../fora"] }, /sair da pasta/],
        [{ faces: ["file:///tmp/x"] }, /URL/],
    ];
    for (const [patch, pattern] of cases) {
        const result = validateManifest(Object.assign({}, GOOD, patch));
        assert.equal(result.ok, false, `${JSON.stringify(patch)} devia reprovar`);
        assert.ok(result.errors.some((error) => pattern.test(error)),
            `${JSON.stringify(patch)}: nenhum erro casou com ${pattern} (${result.errors.join("; ")})`);
    }
});

test("a faixa de API e fechada dos dois lados", () => {
    assert.equal(apiCompatible(PLUGIN_API_MIN), true);
    assert.equal(apiCompatible(PLUGIN_API_CURRENT), true);
    assert.equal(apiCompatible(PLUGIN_API_MIN - 1), false);
    assert.equal(apiCompatible(PLUGIN_API_CURRENT + 1), false);
    assert.equal(apiCompatible(1.5), false);
    assert.equal(apiCompatible("1"), false);
});

test("o meta de um module e o de uma face sao validados separados", () => {
    const module = { module: "clock", title: "Clock", component: "Clock.qml", defaultFace: "digital", services: [] };
    assert.equal(validateModuleMeta(module).ok, true);
    assert.equal(validateModuleMeta(Object.assign({}, module, { module: "vtnc.clock" })).ok, false,
        "o meta do module declara o nome LOCAL; o prefixo e do plugin");
    assert.equal(validateModuleMeta(Object.assign({}, module, { component: "Clock.js" })).ok, false);
    assert.equal(validateModuleMeta(Object.assign({}, module, { placeable: true })).ok, false,
        "placeable sem defaultCell nao diz de que tamanho o widget nasce");

    const face = { face: "digital", module: "vtnc.clock", title: "Digital", component: "Digital.qml" };
    assert.equal(validateFaceMeta(face).ok, true);
    assert.equal(validateFaceMeta(Object.assign({}, face, { module: "clock" })).ok, false,
        "o meta da face declara o nome COMPLETO, porque ela pode vestir module de outro plugin");
});

// ---- o plugin descartavel ----

function writePlugin(root, { id = "shapes", pluginApi = 1, version = "1.0.0" } = {}) {
    mkdirSync(join(root, "modules/hexclock/faces/neon"), { recursive: true });
    writeFileSync(join(root, "plugin.json"), JSON.stringify({
        id, version, pluginApi, author: "user8",
        modules: ["modules/hexclock"],
        faces: ["modules/hexclock/faces/neon"],
    }));
    writeFileSync(join(root, "modules/hexclock/meta.json"), JSON.stringify({
        module: "hexclock", title: "Hex clock", component: "HexClock.qml",
        services: ["clock"], defaultFace: "neon", placeable: true, defaultCell: { w: 4, h: 2 },
        provides: [{ name: "time", kind: "string", doc: "A hora, como o module do vtnc entrega." }],
    }));
    writeFileSync(join(root, "modules/hexclock/HexClock.qml"), "import QtQuick\nItem {}\n");
    writeFileSync(join(root, "modules/hexclock/faces/neon/meta.json"), JSON.stringify({
        face: "neon", module: `${id}.hexclock`, title: "Neon", component: "Neon.qml",
        options: [{ key: "glow", kind: "toggle", title: "Glow", default: true }],
    }));
    writeFileSync(join(root, "modules/hexclock/faces/neon/Neon.qml"), "import QtQuick\nItem {}\n");
    return root;
}

function withTempPlugin(options, body) {
    const dir = mkdtempSync(join(tmpdir(), "vtnc-plugin-"));
    try {
        body(writePlugin(dir, options));
    } finally {
        rmSync(dir, { recursive: true, force: true });
    }
}

test("um plugin que a shell nunca viu carrega inteiro, so por estar no disco", () => {
    withTempPlugin({}, (root) => {
        const catalog = buildCatalog([readPlugin(root, false)]);
        assert.deepEqual(catalog.problems, []);
        assert.equal(catalog.plugins[0].compatible, true);
        assert.equal(catalog.plugins[0].loaded, true);
        assert.deepEqual(moduleIds(catalog), ["shapes.hexclock"]);
        assert.equal(defaultFaceOf(catalog, "shapes.hexclock"), "neon");
        assert.equal(moduleUrl(catalog, "shapes.hexclock"), `file://${root}/modules/hexclock/HexClock.qml`);
        assert.equal(resolvedFaceUrl(catalog, "shapes.hexclock", "neon"),
            `file://${root}/modules/hexclock/faces/neon/Neon.qml`);
        assert.deepEqual(placeableModules(catalog),
            [{ module: "shapes.hexclock", title: "Hex clock", defaultCell: { w: 4, h: 2 } }]);
        assert.equal(optionSchemaOf(catalog, "shapes.hexclock", "neon")[0].key, "glow");
    });
});

test("pluginApi fora da faixa: o plugin continua listado, mas nao entrega nada", () => {
    withTempPlugin({ pluginApi: PLUGIN_API_CURRENT + 1 }, (root) => {
        const catalog = buildCatalog([readPlugin(root, false)]);
        const entry = catalog.plugins[0];
        assert.equal(entry.id, "shapes", "um plugin incompativel ainda aparece na lista");
        assert.equal(entry.version, "1.0.0");
        assert.equal(entry.compatible, false);
        assert.equal(entry.loaded, false);
        assert.ok(entry.problems.some((problem) => /fora da faixa/.test(problem)),
            "a recusa precisa dizer que foi pela FAIXA, nao por erro de carga");
        assert.deepEqual(moduleIds(catalog), [], "nenhum module dele entra no catalogo");
        assert.deepEqual(catalog.faces, []);
    });
});

test("um plugin quebrado nao derruba os outros", () => {
    withTempPlugin({}, (root) => {
        const broken = { root: "/nao/existe", builtin: false, id: "quebrado",
            manifest: null, manifestError: "plugin.json: ENOENT", modules: [], faces: [] };
        const catalog = buildCatalog([broken, readPlugin(root, false)]);
        assert.equal(catalog.plugins.length, 2);
        assert.deepEqual(moduleIds(catalog), ["shapes.hexclock"]);
        assert.ok(catalog.problems.some((problem) => /quebrado/.test(problem)));
    });
});

test("uma face que veste um module inexistente e recusada, e diz qual", () => {
    withTempPlugin({}, (root) => {
        writeFileSync(join(root, "modules/hexclock/faces/neon/meta.json"), JSON.stringify({
            face: "neon", module: "nao.existe", title: "Neon", component: "Neon.qml",
        }));
        const catalog = buildCatalog([readPlugin(root, false)]);
        assert.deepEqual(catalog.faces, []);
        assert.ok(catalog.problems.some((problem) => /nao\.existe/.test(problem)));
    });
});

test("uma face pode vestir o module de OUTRO plugin", () => {
    withTempPlugin({}, (root) => {
        const other = mkdtempSync(join(tmpdir(), "vtnc-face-"));
        try {
            mkdirSync(join(other, "faces/mono"), { recursive: true });
            writeFileSync(join(other, "plugin.json"), JSON.stringify({
                id: "mono", version: "1.0.0", pluginApi: 1, author: "outra pessoa",
                modules: [], faces: ["faces/mono"],
            }));
            writeFileSync(join(other, "faces/mono/meta.json"), JSON.stringify({
                face: "mono", module: "shapes.hexclock", title: "Mono", component: "Mono.qml",
            }));
            const catalog = buildCatalog([readPlugin(root, false), readPlugin(other, false)]);
            assert.deepEqual(catalog.problems, []);
            assert.deepEqual(facesOf(catalog, "shapes.hexclock").map((face) => face.face).sort(),
                ["mono", "neon"]);
            assert.equal(resolvedFaceUrl(catalog, "shapes.hexclock", "mono"),
                `file://${other}/faces/mono/Mono.qml`);
        } finally {
            rmSync(other, { recursive: true, force: true });
        }
    });
});

// ---- o vtnc, lido pelo mesmo caminho que qualquer plugin ----

const catalog = loadCatalog();

test("o vtnc e um plugin, e carrega sem problema nenhum", () => {
    const vtnc = catalog.plugins.find((plugin) => plugin.id === "vtnc");
    assert.ok(vtnc, "o plugin embutido precisa aparecer na varredura");
    assert.equal(vtnc.builtin, true);
    assert.equal(vtnc.compatible, true);
    assert.deepEqual(vtnc.problems, []);
    assert.deepEqual(catalog.problems, []);
});

// O indice no manifesto e o preco de nao varrer a arvore em tempo de
// execucao (ver core/plugin-manifest.mjs). Este teste e quem cobra o
// preco: acrescentar uma pasta sem lista-la no manifesto reprova aqui.
test("o manifesto do vtnc lista exatamente as pastas que existem no disco", () => {
    const manifest = JSON.parse(readFileSync(join(repoRoot, "plugin.json"), "utf8"));
    const moduleDirs = readdirSync(join(repoRoot, "modules"), { withFileTypes: true })
        .filter((entry) => entry.isDirectory()).map((entry) => `modules/${entry.name}`).sort();
    assert.deepEqual(manifest.modules.slice().sort(), moduleDirs);

    const faceDirs = [];
    for (const dir of moduleDirs) {
        const faces = join(repoRoot, dir, "faces");
        if (!existsSync(faces)) continue;
        for (const entry of readdirSync(faces, { withFileTypes: true })) {
            if (entry.isDirectory()) faceDirs.push(`${dir}/faces/${entry.name}`);
        }
    }
    assert.deepEqual(manifest.faces.slice().sort(), faceDirs.sort());
});

test("todo module aponta para um QML que existe, e toda face tambem", () => {
    for (const entry of catalog.modules) {
        assert.ok(existsSync(entry.componentUrl.replace("file://", "")),
            `${entry.id}: ${entry.componentUrl} nao existe no disco`);
    }
    for (const entry of catalog.faces) {
        assert.ok(existsSync(entry.componentUrl.replace("file://", "")),
            `${entry.moduleId}/${entry.face}: ${entry.componentUrl} nao existe no disco`);
    }
});

// Quem desenha menu le a entrada do catalogo, e nao o meta dentro dela.
// Sem este teste, um campo que fica so em `meta` vira `undefined` no QML,
// que nao quebra nada: o rotulo some e o controle deixa de existir na
// tela, em silencio. Foi o que aconteceu com o chip de face na 0.512.
test("a entrada do catalogo carrega o que a tela precisa, sem abrir o meta", () => {
    for (const entry of catalog.modules) {
        assert.equal(typeof entry.title, "string");
        assert.ok(entry.title.length > 0, `${entry.id} sem title na entrada`);
    }
    for (const entry of catalog.faces) {
        assert.equal(typeof entry.title, "string");
        assert.ok(entry.title.length > 0, `${entry.moduleId}/${entry.face} sem title na entrada`);
        assert.ok(Array.isArray(entry.options), `${entry.moduleId}/${entry.face} sem options na entrada`);
    }
});

test("o defaultFace de cada module e uma face que ele realmente tem", () => {
    for (const entry of catalog.modules) {
        const fallback = defaultFaceOf(catalog, entry.id);
        assert.ok(fallback, `${entry.id} nao declara defaultFace`);
        assert.ok(faceMeta(catalog, entry.id, fallback),
            `${entry.id}: defaultFace "${fallback}" nao existe entre as faces dele`);
        assert.ok(facesOf(catalog, entry.id).length > 0, `${entry.id} nao tem face nenhuma`);
    }
});

test("uma face que nao existe cai no padrao do module, em vez de sumir", () => {
    const fallback = resolvedFaceUrl(catalog, "vtnc.clock", "nao-existe");
    assert.equal(fallback, resolvedFaceUrl(catalog, "vtnc.clock", defaultFaceOf(catalog, "vtnc.clock")));
    assert.notEqual(fallback, "");
});

// As `required property` de uma face sao exatamente o que ela exige do seu
// module. Fora as que o proprio QML declara dentro de um delegate
// (`modelData`, `index`), que vem do Repeater e nao do module - por isso a
// leitura so pega as declaradas na raiz do arquivo, com quatro espacos.
function requiredRootProperties(qmlPath) {
    const source = readFileSync(qmlPath, "utf8");
    const names = [];
    for (const line of source.split("\n")) {
        const match = /^ {4}required property \w+ (\w+)/.exec(line);
        if (match) names.push(match[1]);
    }
    return names;
}

// O coracao da 3.5b.
test("nenhuma face exige do module algo que o module nao publica", () => {
    for (const entry of catalog.faces) {
        const published = providesOf(catalog, entry.moduleId).map((published) => published.name);
        for (const name of requiredRootProperties(entry.componentUrl.replace("file://", ""))) {
            if (FRAMEWORK_PROPERTIES.includes(name)) continue;
            assert.ok(published.includes(name),
                `${entry.moduleId}/${entry.face} exige "${name}", que o meta do module nao publica (3.5b)`);
        }
    }
});

test("o que o module publica esta documentado, nao so nomeado", () => {
    for (const entry of catalog.modules) {
        const names = providesOf(catalog, entry.id).map((published) => published.name);
        assert.equal(new Set(names).size, names.length, `${entry.id} publica o mesmo nome duas vezes`);
        assert.equal(validateModuleMeta(entry.meta).ok, true,
            `${entry.id}: ${validateModuleMeta(entry.meta).errors.join("; ")}`);
    }
});

// A lista de faces nao pode voltar a existir escrita duas vezes: era isso
// que havia antes da 0.509, no meta do module e num switch dentro do QML.
test("nenhum module QML escolhe face por nome na mao", () => {
    for (const entry of catalog.modules) {
        const folder = join(repoRoot, entry.dir);
        for (const file of readdirSync(folder).filter((name) => name.endsWith(".qml"))) {
            const source = readFileSync(join(folder, file), "utf8");
            for (const face of facesOf(catalog, entry.id)) {
                assert.ok(!source.includes(`case "${face.face}":`),
                    `${entry.dir}/${file} ainda escolhe a face "${face.face}" num switch`);
            }
        }
    }
});

// O mesmo para o Page: ele era o outro lugar onde a lista de modules vivia
// escrita a mao, e e por causa dele que nada de fora da shell desenhava.
test("o Page nao nomeia module nenhum", () => {
    const source = readFileSync(join(repoRoot, "page", "Page.qml"), "utf8");
    for (const entry of catalog.modules) {
        assert.ok(!source.includes(entry.id), `page/Page.qml ainda nomeia ${entry.id}`);
    }
});

test("a varredura acha o vtnc mesmo sem pasta de plugins instalada", () => {
    const previous = process.env.VTNC_PLUGIN_DIR;
    process.env.VTNC_PLUGIN_DIR = join(tmpdir(), "vtnc-sem-plugins-nenhum");
    try {
        const scanned = scanPlugins();
        assert.equal(scanned.length, 1);
        assert.equal(scanned[0].manifest.id, "vtnc");
    } finally {
        if (previous === undefined) delete process.env.VTNC_PLUGIN_DIR;
        else process.env.VTNC_PLUGIN_DIR = previous;
    }
});

test("a varredura acha um plugin instalado na pasta de plugins", () => {
    const previous = process.env.VTNC_PLUGIN_DIR;
    const dir = mkdtempSync(join(tmpdir(), "vtnc-plugins-"));
    try {
        writePlugin(mkdirSync(join(dir, "shapes"), { recursive: true }) ?? join(dir, "shapes"));
        process.env.VTNC_PLUGIN_DIR = dir;
        const found = loadCatalog();
        assert.deepEqual(found.plugins.map((plugin) => plugin.id).sort(), ["shapes", "vtnc"]);
        assert.ok(moduleEntry(found, "shapes.hexclock"), "o module do plugin instalado precisa entrar");
        assert.ok(isPlaceableModule(found, "shapes.hexclock"));
        assert.equal(moduleMeta(found, "shapes.hexclock").title, "Hex clock");
    } finally {
        if (previous === undefined) delete process.env.VTNC_PLUGIN_DIR;
        else process.env.VTNC_PLUGIN_DIR = previous;
        rmSync(dir, { recursive: true, force: true });
    }
});
