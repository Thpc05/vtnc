// Camada 1 da 0.509: o registro dos types e dos styles, e a interface que
// cada type publica (decisao 3.5b).
//
// O teste que importa aqui e o que LE O QML de cada style e reprova se ele
// exigir do type alguma coisa que o type nao publicou. Sem ele, `provides`
// seria mais um comentario que envelhece: alguem acrescenta uma
// `required property` num style, o type passa a entregar aquilo na mao, e
// a documentacao que um terceiro le para escrever o proprio style fica
// mentindo em silencio.

import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync, readdirSync, existsSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

import {
    TYPE_METAS,
    STYLE_METAS,
    typeMeta,
    stylesOf,
    styleMeta,
    defaultStyleOf,
    styleComponentPath,
    resolvedStylePath,
    providesOf,
    typeFolder,
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
    const dir = join(widgetsDir, widgetFolder, "styles");
    if (!existsSync(dir)) return [];
    return readdirSync(dir, { withFileTypes: true })
        .filter((entry) => entry.isDirectory())
        .map((entry) => entry.name);
}

// As `required property` de um style sao exatamente o que ele exige do seu
// type. Fora as que o proprio QML declara dentro de um delegate (`modelData`,
// `index`), que vem do Repeater e nao do type - por isso a leitura so pega
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

test("todo type tem meta, e todo meta tem um type unico", () => {
    const types = TYPE_METAS.map((meta) => meta.type);
    assert.equal(new Set(types).size, types.length, "dois metas declaram o mesmo type");
    for (const meta of TYPE_METAS) {
        assert.ok(meta.type.includes("."), `${meta.type} nao tem prefixo de fonte (decisao 3.1)`);
        assert.equal(typeof meta.title, "string");
        assert.ok(Array.isArray(meta.services), `${meta.type} precisa declarar services, nem que seja []`);
    }
});

test("o registro conhece exatamente as pastas que existem no disco", () => {
    const onDisk = widgetFolders().sort();
    const registered = TYPE_METAS.map((meta) => typeFolder(meta.type)).sort();
    assert.deepEqual(registered, onDisk,
        "uma pasta de widget nao esta no registro (ou o registro nomeia uma que nao existe)");
});

test("os styles de um type sao os que existem na pasta dele", () => {
    for (const meta of TYPE_METAS) {
        const folder = typeFolder(meta.type);
        const onDisk = styleFolders(folder).sort();
        const registered = stylesOf(meta.type).map((style) => style.style).sort();
        assert.deepEqual(registered, onDisk,
            `${meta.type}: o registro e a pasta styles/ discordam`);
        assert.ok(onDisk.length > 0, `${meta.type} nao tem style nenhum`);
    }
});

test("todo style aponta para um type que existe e para um QML que existe", () => {
    for (const style of STYLE_METAS) {
        assert.ok(typeMeta(style.type), `style ${style.style} aponta para o type inexistente ${style.type}`);
        const path = styleComponentPath(style.type, style.style);
        const onDisk = join(widgetsDir, typeFolder(style.type), path);
        assert.ok(existsSync(onDisk), `${style.type}/${style.style}: ${path} nao existe no disco`);
    }
});

test("o defaultStyle de cada type e um style que ele realmente tem", () => {
    for (const meta of TYPE_METAS) {
        const fallback = defaultStyleOf(meta.type);
        assert.ok(fallback, `${meta.type} nao declara defaultStyle`);
        assert.ok(styleMeta(meta.type, fallback),
            `${meta.type}: defaultStyle "${fallback}" nao existe entre os styles dele`);
    }
});

test("um style que nao existe cai no padrao do type, em vez de sumir", () => {
    const fallback = resolvedStylePath("vtnc.clock", "nao-existe");
    assert.equal(fallback, styleComponentPath("vtnc.clock", defaultStyleOf("vtnc.clock")));
    assert.notEqual(fallback, null);
});

// O coracao da 3.5b.
test("nenhum style exige do type algo que o type nao publica", () => {
    for (const style of STYLE_METAS) {
        const qmlPath = join(widgetsDir, typeFolder(style.type), styleComponentPath(style.type, style.style));
        const published = providesOf(style.type).map((entry) => entry.name);
        for (const name of requiredRootProperties(qmlPath)) {
            if (FRAMEWORK_PROPERTIES.includes(name)) continue;
            assert.ok(published.includes(name),
                `${style.type}/${style.style} exige "${name}", que o meta do type nao publica (decisao 3.5b)`);
        }
    }
});

test("o que o type publica esta documentado, nao so nomeado", () => {
    for (const meta of TYPE_METAS) {
        for (const entry of providesOf(meta.type)) {
            assert.equal(typeof entry.name, "string");
            assert.ok(entry.name.length > 0);
            assert.ok(["string", "int", "real", "bool", "var"].includes(entry.kind),
                `${meta.type}.${entry.name}: kind "${entry.kind}" nao e um tipo QML conhecido`);
            assert.ok(typeof entry.doc === "string" && entry.doc.length > 10,
                `${meta.type}.${entry.name} nao tem descricao (decisao 3.5b pede documentar, nao so listar)`);
        }
        const names = providesOf(meta.type).map((entry) => entry.name);
        assert.equal(new Set(names).size, names.length, `${meta.type} publica o mesmo nome duas vezes`);
    }
});

// A lista de styles nao pode voltar a existir escrita duas vezes: era isso
// que havia antes da 0.509, no meta do type e num switch dentro do QML
// dele, com nada obrigando as duas a concordarem.
test("nenhum type QML escolhe style por nome na mao", () => {
    for (const meta of TYPE_METAS) {
        const folder = typeFolder(meta.type);
        const files = readdirSync(join(widgetsDir, folder)).filter((f) => f.endsWith(".qml"));
        for (const file of files) {
            const source = readFileSync(join(widgetsDir, folder, file), "utf8");
            for (const style of stylesOf(meta.type)) {
                assert.ok(!source.includes(`case "${style.style}":`),
                    `${folder}/${file} ainda escolhe o style "${style.style}" num switch; quem sabe isso e o registro`);
            }
        }
    }
});
