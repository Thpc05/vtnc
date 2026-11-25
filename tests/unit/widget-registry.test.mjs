// Camada 1 da 0.509: o registro dos modules e das faces, e a interface que
// cada module publica (decisao 3.5b).
//
// O teste que importa aqui e o que LE O QML de cada face e reprova se ele
// exigir do module alguma coisa que o module nao publicou. Sem ele, `provides`
// seria mais um comentario que envelhece: alguem acrescenta uma
// `required property` numa face, o module passa a entregar aquilo na mao, e
// a documentacao que um terceiro le para escrever o propria face fica
// mentindo em silencio.

import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync, readdirSync, existsSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

import {
    MODULE_METAS,
    FACE_METAS,
    moduleMeta,
    facesOf,
    faceMeta,
    defaultFaceOf,
    faceComponentPath,
    resolvedFacePath,
    providesOf,
    moduleFolder,
    FRAMEWORK_PROPERTIES,
} from "../../core/widget-registry.mjs";

const repoRoot = join(dirname(fileURLToPath(import.meta.url)), "..", "..");
const widgetsDir = join(repoRoot, "widgets");

function widgetFolders() {
    return readdirSync(widgetsDir, { withFileTypes: true })
        .filter((entry) => entry.isDirectory())
        .map((entry) => entry.name);
}

function styleFolders(widgetFolder) {
    const dir = join(widgetsDir, widgetFolder, "faces");
    if (!existsSync(dir)) return [];
    return readdirSync(dir, { withFileTypes: true })
        .filter((entry) => entry.isDirectory())
        .map((entry) => entry.name);
}

// As `required property` de uma face sao exatamente o que ele exige do seu
// module. Fora as que o proprio QML declara dentro de um delegate (`modelData`,
// `index`), que vem do Repeater e nao do module - por isso a leitura so pega
// as declaradas na raiz do arquivo, com a indentacao de quatro espacos.
function requiredRootProperties(qmlPath) {
    const source = readFileSync(qmlPath, "utf8");
    const names = [];
    for (const line of source.split("\n")) {
        const match = /^ {4}required property \w+ (\w+)/.exec(line);
        if (match) names.push(match[1]);
    }
    return names;
}

test("todo module tem meta, e todo meta tem um module unico", () => {
    const modules = MODULE_METAS.map((meta) => meta.module);
    assert.equal(new Set(modules).size, modules.length, "dois metas declaram o mesmo module");
    for (const meta of MODULE_METAS) {
        assert.ok(meta.module.includes("."), `${meta.module} nao tem prefixo de fonte (decisao 3.1)`);
        assert.equal(typeof meta.title, "string");
        assert.ok(Array.isArray(meta.services), `${meta.module} precisa declarar services, nem que seja []`);
    }
});

test("o registro conhece exatamente as pastas que existem no disco", () => {
    const onDisk = widgetFolders().sort();
    const registered = MODULE_METAS.map((meta) => moduleFolder(meta.module)).sort();
    assert.deepEqual(registered, onDisk,
        "uma pasta de widget nao esta no registro (ou o registro nomeia uma que nao existe)");
});

test("as faces de um module sao os que existem na pasta dele", () => {
    for (const meta of MODULE_METAS) {
        const folder = moduleFolder(meta.module);
        const onDisk = styleFolders(folder).sort();
        const registered = facesOf(meta.module).map((face) => face.face).sort();
        assert.deepEqual(registered, onDisk,
            `${meta.module}: o registro e a pasta faces/ discordam`);
        assert.ok(onDisk.length > 0, `${meta.module} nao tem face nenhum`);
    }
});

test("toda face aponta para um module que existe e para um QML que existe", () => {
    for (const face of FACE_METAS) {
        assert.ok(moduleMeta(face.module), `face ${face.face} aponta para o module inexistente ${face.module}`);
        const path = faceComponentPath(face.module, face.face);
        const onDisk = join(widgetsDir, moduleFolder(face.module), path);
        assert.ok(existsSync(onDisk), `${face.module}/${face.face}: ${path} nao existe no disco`);
    }
});

test("o defaultFace de cada module e uma face que ele realmente tem", () => {
    for (const meta of MODULE_METAS) {
        const fallback = defaultFaceOf(meta.module);
        assert.ok(fallback, `${meta.module} nao declara defaultFace`);
        assert.ok(faceMeta(meta.module, fallback),
            `${meta.module}: defaultFace "${fallback}" nao existe entre as faces dele`);
    }
});

test("uma face que nao existe cai no padrao do module, em vez de sumir", () => {
    const fallback = resolvedFacePath("vtnc.clock", "nao-existe");
    assert.equal(fallback, faceComponentPath("vtnc.clock", defaultFaceOf("vtnc.clock")));
    assert.notEqual(fallback, null);
});

// O coracao da 3.5b.
test("nenhuma face exige do module algo que o module nao publica", () => {
    for (const face of FACE_METAS) {
        const qmlPath = join(widgetsDir, moduleFolder(face.module), faceComponentPath(face.module, face.face));
        const published = providesOf(face.module).map((entry) => entry.name);
        for (const name of requiredRootProperties(qmlPath)) {
            if (FRAMEWORK_PROPERTIES.includes(name)) continue;
            assert.ok(published.includes(name),
                `${face.module}/${face.face} exige "${name}", que o meta do module nao publica (decisao 3.5b)`);
        }
    }
});

test("o que o module publica esta documentado, nao so nomeado", () => {
    for (const meta of MODULE_METAS) {
        for (const entry of providesOf(meta.module)) {
            assert.equal(typeof entry.name, "string");
            assert.ok(entry.name.length > 0);
            assert.ok(["string", "int", "real", "bool", "var"].includes(entry.kind),
                `${meta.module}.${entry.name}: kind "${entry.kind}" nao e um tipo QML conhecido`);
            assert.ok(typeof entry.doc === "string" && entry.doc.length > 10,
                `${meta.module}.${entry.name} nao tem descricao (decisao 3.5b pede documentar, nao so listar)`);
        }
        const names = providesOf(meta.module).map((entry) => entry.name);
        assert.equal(new Set(names).size, names.length, `${meta.module} publica o mesmo nome duas vezes`);
    }
});

// A lista de faces nao pode voltar a existir escrita duas vezes: era isso
// que havia antes da 0.509, no meta do module e num switch dentro do QML
// dele, com nada obrigando as duas a concordarem.
test("nenhum module QML escolhe face por nome na mao", () => {
    for (const meta of MODULE_METAS) {
        const folder = moduleFolder(meta.module);
        const files = readdirSync(join(widgetsDir, folder)).filter((f) => f.endsWith(".qml"));
        for (const file of files) {
            const source = readFileSync(join(widgetsDir, folder, file), "utf8");
            for (const face of facesOf(meta.module)) {
                assert.ok(!source.includes(`case "${face.face}":`),
                    `${folder}/${file} ainda escolhe a face "${face.face}" num switch; quem sabe isso e o registro`);
            }
        }
    }
});
