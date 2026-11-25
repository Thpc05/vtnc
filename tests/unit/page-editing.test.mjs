import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";
import {
    defaultPage, PAGE_SETTABLE_KEYS, parsePageSetValue, validatePageSet,
} from "../../core/config-shape.mjs";
import { emptyStateIsland, exclusiveZone, islandGeometry, EMPTY_STATE_CELLS } from "../../core/grid.mjs";
import { WIDGET_CATALOG, SETTINGS_ONLY_MODULES, catalogEntry, isPlaceableModule } from "../../core/widget-catalog.mjs";

const repoRoot = join(dirname(fileURLToPath(import.meta.url)), "..", "..");

test("defaultPage is an empty page with a usable grid", () => {
    const page = defaultPage();
    assert.deepEqual(page.widgets, []);
    assert.ok(page.grid.cols >= 1 && page.grid.rows >= 1);
});

test("page set only accepts grid and widgets", () => {
    assert.deepEqual(PAGE_SETTABLE_KEYS, ["grid", "widgets"]);
    assert.match(validatePageSet("lifecycle", "popup"), /unknown key/);
});

test("a grid needs whole numbers of at least 1 on both axes", () => {
    assert.equal(validatePageSet("grid", { cols: 12, rows: 6 }), null);
    assert.match(validatePageSet("grid", { cols: 0, rows: 6 }), /at least 1/);
    assert.match(validatePageSet("grid", { cols: 2.5, rows: 6 }), /whole numbers/);
    assert.match(validatePageSet("grid", { cols: 12 }), /at least 1/);
    assert.match(validatePageSet("grid", "12x6"), /JSON object/);
});

// Sem w/h o widget nasce invisivel e sem x/y ele empilha no canto: os dois
// casos parecem "o botao nao fez nada" para quem esta usando.
test("a widget instance needs a module and a complete cell", () => {
    const ok = [{ module: "vtnc.clock", cell: { x: 0, y: 0, w: 6, h: 2 } }];
    assert.equal(validatePageSet("widgets", ok), null);
    assert.match(validatePageSet("widgets", [{ module: "vtnc.clock" }]), /cell/);
    assert.match(validatePageSet("widgets", [{ cell: { x: 0, y: 0, w: 1, h: 1 } }]), /module/);
    assert.match(validatePageSet("widgets", [{ module: "vtnc.clock", cell: { x: 0, y: 0, w: 0, h: 1 } }]), /1 or more/);
    assert.match(validatePageSet("widgets", [{ module: "vtnc.clock", cell: { x: -1, y: 0, w: 1, h: 1 } }]), /0 or more/);
    assert.match(validatePageSet("widgets", {}), /JSON array/);
});

test("face is optional on a widget instance, but must be a string", () => {
    const withStyle = [{ module: "vtnc.clock", face: "panel", cell: { x: 0, y: 0, w: 1, h: 1 } }];
    assert.equal(validatePageSet("widgets", withStyle), null);
    const badStyle = [{ module: "vtnc.clock", face: 3, cell: { x: 0, y: 0, w: 1, h: 1 } }];
    assert.match(validatePageSet("widgets", badStyle), /face/);
});

test("parsePageSetValue turns the CLI's JSON argument into the value, or undefined", () => {
    assert.deepEqual(parsePageSetValue("grid", '{"cols":3,"rows":2}'), { cols: 3, rows: 2 });
    assert.equal(parsePageSetValue("grid", "not json"), undefined);
    assert.match(validatePageSet("grid", parsePageSetValue("grid", "not json")), /JSON object/);
});

// --- o estado empty (14.3) -------------------------------------------------

test("an island with no page shrinks to the empty dot, keeping everything else", () => {
    const island = { name: "bar", anchor: { top: true }, offset: { x: 2, y: 1 }, size: { w: 40, h: 4 }, gap: 0, page: "gone" };
    const empty = emptyStateIsland(island);
    assert.deepEqual(empty.size, { w: EMPTY_STATE_CELLS, h: EMPTY_STATE_CELLS });
    assert.equal(empty.name, "bar");
    assert.deepEqual(empty.anchor, island.anchor);
    assert.deepEqual(empty.offset, island.offset);
    // e nao estraga o original
    assert.deepEqual(island.size, { w: 40, h: 4 });
});

// O ponto da 14.3 que custa dinheiro: a reserva encolhe junto. Uma island
// vazia que seguisse reservando quarenta celulas empurraria as janelas do
// usuario por nada, e ele nao teria como ver o porque.
test("the empty dot reserves its own 2 cells, not the island's full size", () => {
    const island = { anchor: { top: true, left: true, right: true }, size: { w: 40, h: 4 }, gap: 0, page: "gone" };
    assert.equal(exclusiveZone(island, 8).px, 32);
    assert.equal(exclusiveZone(emptyStateIsland(island), 8).px, 16);
});

test("the empty dot is square on screen", () => {
    const geometry = islandGeometry(emptyStateIsland({ anchor: { top: true }, size: { w: 40, h: 4 }, offset: { x: 0, y: 0 } }), 8);
    assert.equal(geometry.width, geometry.height);
});

// --- o catalogo (8.2) ------------------------------------------------------

test("the catalogue only offers modules page/Page.qml can actually draw", () => {
    const pageQml = readFileSync(join(repoRoot, "page", "Page.qml"), "utf8");
    for (const entry of WIDGET_CATALOG) {
        assert.ok(pageQml.includes(`case "${entry.module}":`),
            `${entry.module} está no catálogo mas Page.qml não sabe desenhá-lo`);
        assert.ok(entry.defaultCell.w >= 1 && entry.defaultCell.h >= 1,
            `${entry.module} nasceria invisível`);
    }
});

// A Settings e feita dos mesmos widgets de verdade (decisao 8.3), mas eles
// nao sao para o usuario espalhar por ai: oferecer um island-editor dentro
// de uma page qualquer seria oferecer uma tela de configuracao solta.
test("the Settings' own widgets are drawable but never offered in the catalogue", () => {
    const pageQml = readFileSync(join(repoRoot, "page", "Page.qml"), "utf8");
    for (const module of SETTINGS_ONLY_MODULES) {
        assert.ok(pageQml.includes(`case "${module}":`), `${module} não é desenhável`);
        assert.equal(isPlaceableModule(module), false, `${module} não devia estar no catálogo`);
        assert.equal(catalogEntry(module), null);
    }
});

test("a widget instance the catalogue doesn't know is still valid config", () => {
    // Uma extensao de terceiro instala o proprio module: o validador nao pode
    // exigir que ele esteja nesta lista, que e so o que o editor OFERECE.
    assert.equal(validatePageSet("widgets", [{ module: "user8.weather", cell: { x: 0, y: 0, w: 2, h: 2 } }]), null);
    assert.equal(isPlaceableModule("user8.weather"), false);
});
