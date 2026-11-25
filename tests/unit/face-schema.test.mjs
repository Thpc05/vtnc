// Camada 1 da 0.510: o schema de opcoes de face.
//
// Quase todo teste aqui existe por causa da decisao 3.4d — a face
// DESCREVE, a shell DECIDE. Eles conferem que a shell recusa, limita e
// descarta por conta propria, sem depender de a face ter se comportado.

import { test } from "node:test";
import assert from "node:assert/strict";

import {
    CONTROL_KINDS,
    NUMBER_UNITS,
    COLOR_ROLES,
    TEXT_MAX_LENGTH,
    validateOptionDeclaration,
    validateOptionValue,
    partitionSchema,
    usableSchema,
    resolveOptions,
    resolveFaceOptions,
    storedOptionsFor,
    withOption,
} from "../../core/face-schema.mjs";

import { FACE_METAS, optionSchemaOf } from "../../core/widget-registry.mjs";
import { PROVISIONAL_PALETTE, colorForRole } from "../../core/palette.mjs";

const toggle = { key: "showSeconds", kind: "toggle", title: "Show seconds", default: true };
const number = { key: "fontSize", kind: "number", title: "Font size", default: 20, min: 8, max: 72, step: 2, unit: "px" };
const choice = {
    key: "align", kind: "choice", title: "Align", default: "center",
    choices: [{ value: "left", title: "Left" }, { value: "center", title: "Center" }],
};
const text = { key: "label", kind: "text", title: "Label", default: "" };
const role = { key: "color", kind: "role", title: "Colour", default: "text" };

test("a lista de controles e fechada e tem os cinco da decisao 3.4b", () => {
    assert.deepEqual(CONTROL_KINDS, ["toggle", "number", "choice", "text", "role"]);
});

test("uma declaracao boa de cada controle passa", () => {
    for (const declaration of [toggle, number, choice, text, role]) {
        assert.equal(validateOptionDeclaration(declaration), null, `${declaration.kind} devia passar`);
    }
});

test("um controle fora da lista fechada e recusado pelo nome", () => {
    const error = validateOptionDeclaration({ key: "x", kind: "slider", title: "X", default: 1 });
    assert.match(error, /slider/);
    assert.match(error, /toggle, number, choice, text, role/);
});

test("uma chave que nao e identificador e recusada", () => {
    for (const key of ["", "com espaco", "1primeiro", "com-hifen", 42, undefined]) {
        assert.ok(validateOptionDeclaration({ key: key, kind: "toggle", title: "T", default: true }),
            `a chave ${JSON.stringify(key)} devia ser recusada`);
    }
});

test("toda opcao precisa de title e de default", () => {
    assert.match(validateOptionDeclaration({ key: "a", kind: "toggle", default: true }), /title/);
    assert.match(validateOptionDeclaration({ key: "a", kind: "toggle", title: "A" }), /default/);
});

test("um default que nao serve para o proprio controle e recusado", () => {
    const error = validateOptionDeclaration({ key: "a", kind: "number", title: "A", min: 1, max: 10, default: 99 });
    assert.match(error, /default/);
    assert.match(error, /entre 1 e 10/);
});

test("number precisa de min e max, e min menor que max", () => {
    assert.match(validateOptionDeclaration({ key: "a", kind: "number", title: "A", default: 1 }), /min e max/);
    assert.match(validateOptionDeclaration({ key: "a", kind: "number", title: "A", default: 1, min: 10, max: 1 }), /menor que max/);
});

test("a unidade de um number vem da lista fechada (2b.4)", () => {
    assert.deepEqual(NUMBER_UNITS, ["plain", "cell", "px"]);
    assert.match(validateOptionDeclaration(Object.assign({}, number, { unit: "em" })), /unidade "em"/);
});

test("choice precisa de duas escolhas, sem value repetido", () => {
    assert.match(validateOptionDeclaration({ key: "a", kind: "choice", title: "A", default: "x", choices: [{ value: "x", title: "X" }] }), /duas escolhas/);
    const repeated = { key: "a", kind: "choice", title: "A", default: "x", choices: [{ value: "x", title: "X" }, { value: "x", title: "Y" }] };
    assert.match(validateOptionDeclaration(repeated), /repete um value/);
});

// --- o valor, que e onde a shell impoe (3.4d) -------------------------

test("a shell recusa um numero fora da faixa que a face pediu", () => {
    assert.equal(validateOptionValue(number, 20), null);
    assert.match(validateOptionValue(number, 7), /entre 8 e 72/);
    assert.match(validateOptionValue(number, 73), /entre 8 e 72/);
    assert.match(validateOptionValue(number, "20"), /numero/);
});

test("a shell recusa uma escolha que nao esta na lista", () => {
    assert.equal(validateOptionValue(choice, "left"), null);
    assert.match(validateOptionValue(choice, "right"), /left, center/);
});

test("a shell recusa um papel de cor que nao existe, e so aceita os sete", () => {
    assert.deepEqual(COLOR_ROLES, ["primary", "accent", "surface", "surfaceAlt", "text", "textMuted", "border"]);
    for (const value of COLOR_ROLES) assert.equal(validateOptionValue(role, value), null);
    assert.match(validateOptionValue(role, "#ff0000"), /papel de cor/);
    assert.match(validateOptionValue(role, "roxo"), /papel de cor/);
});

test("a shell impoe teto no texto, a face nao escolhe", () => {
    assert.equal(validateOptionValue(text, "x".repeat(TEXT_MAX_LENGTH)), null);
    assert.match(validateOptionValue(text, "x".repeat(TEXT_MAX_LENGTH + 1)), /passa de/);
});

// --- uma declaracao ruim nao derruba a face inteiro (3.4d) -----------

test("uma declaracao ruim e descartada e as boas continuam", () => {
    const { accepted, rejected } = partitionSchema([toggle, { key: "x", kind: "slider", title: "X", default: 1 }, role]);
    assert.deepEqual(accepted.map((a) => a.key), ["showSeconds", "color"]);
    assert.equal(rejected.length, 1);
    assert.match(rejected[0].error, /slider/);
});

test("a mesma chave duas vezes: a segunda e descartada, com motivo", () => {
    const { accepted, rejected } = partitionSchema([toggle, Object.assign({}, toggle, { default: false })]);
    assert.equal(accepted.length, 1);
    assert.match(rejected[0].error, /duas vezes/);
});

test("um schema que nem e lista nao quebra nada", () => {
    for (const bad of [undefined, null, 42, "opcoes", {}]) {
        assert.deepEqual(usableSchema(bad), []);
        assert.deepEqual(resolveOptions(bad, { a: 1 }), {});
    }
});

// --- os valores que chegam à face -----------------------------------

test("sem nada guardado, a face recebe os defaults que ele declarou", () => {
    assert.deepEqual(resolveOptions([toggle, number], {}), { showSeconds: true, fontSize: 20 });
});

test("um valor guardado que nao serve mais cai no default", () => {
    assert.deepEqual(resolveOptions([number], { fontSize: 999 }), { fontSize: 20 });
    assert.deepEqual(resolveOptions([choice], { align: "diagonal" }), { align: "center" });
});

test("a face nunca recebe uma chave que nao declarou", () => {
    const values = resolveOptions([toggle], { showSeconds: false, intruso: 1 });
    assert.deepEqual(values, { showSeconds: false });
});

test("o papel de cor chega à face ja virado cor, nunca o nome", () => {
    const painted = resolveFaceOptions([role], { color: "accent" });
    assert.equal(painted.color, PROVISIONAL_PALETTE.accent);
    assert.notEqual(painted.color, "accent");
});

test("a paleta cobre todos os papeis, e um papel desconhecido nao vira vazio", () => {
    for (const name of COLOR_ROLES) {
        assert.match(PROVISIONAL_PALETTE[name], /^#[0-9a-f]{6}$/, `o papel ${name} nao tem cor`);
    }
    assert.equal(colorForRole("nao-existe"), PROVISIONAL_PALETTE.text);
});

// --- a decisao 4.4 ----------------------------------------------------

test("as opcoes ficam guardadas por face, e trocar e voltar nao perde nada", () => {
    let widget = { module: "vtnc.clock", face: "digital", cell: { x: 0, y: 0, w: 6, h: 2 } };
    widget = withOption(widget, "digital", "fontSize", 32);
    widget = withOption(widget, "compact", "showSeconds", true);

    assert.deepEqual(storedOptionsFor(widget, "digital"), { fontSize: 32 });
    assert.deepEqual(storedOptionsFor(widget, "compact"), { showSeconds: true });

    // mexer numa face nao encosta no outro
    widget = withOption(widget, "digital", "fontSize", 10);
    assert.deepEqual(storedOptionsFor(widget, "compact"), { showSeconds: true });
});

test("withOption nao muda a instancia original", () => {
    const widget = { module: "vtnc.clock", cell: { x: 0, y: 0, w: 1, h: 1 } };
    const next = withOption(widget, "digital", "fontSize", 32);
    assert.equal(widget.options, undefined);
    assert.deepEqual(next.options.digital, { fontSize: 32 });
});

test("storedOptionsFor aguenta instancia sem options nenhuma", () => {
    assert.deepEqual(storedOptionsFor({}, "digital"), {});
    assert.deepEqual(storedOptionsFor({ options: "nao e objeto" }, "digital"), {});
    assert.deepEqual(storedOptionsFor(undefined, "digital"), {});
});

// --- as faces de verdade ---------------------------------------------

test("toda face que existe declara opcoes que a shell aceita inteiras", () => {
    for (const face of FACE_METAS) {
        const declared = optionSchemaOf(face.module, face.face);
        const { rejected } = partitionSchema(declared);
        assert.deepEqual(rejected, [],
            `${face.module}/${face.face} declara opcao que a shell recusa: ${JSON.stringify(rejected)}`);
    }
});
