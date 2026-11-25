// O schema de opcoes de uma face (0.510, decisoes 3.4 / 3.4b / 3.4c / 3.4d).
//
// A regra que da forma a este arquivo inteiro e a 3.4d: **a face DESCREVE,
// a shell DECIDE**. Uma face entrega aqui uma lista de declaracoes - dado,
// nunca codigo: nenhuma funcao dele e chamada pela Settings, nenhum QML
// dele e executado por ela. Quem decide o que e um valor aceitavel e este
// modulo, nao a face, e e por isso que `min`/`max`, a lista do `choice` e
// os papeis de cor sao impostos aqui, de fora.
//
// E a razao de uma declaracao ruim ser DESCARTADA em vez de derrubar
// alguma coisa: a shell tem de ser modulavel e confiavel ao mesmo tempo, e
// um unico meta mal escrito de terceiro nao pode tirar tudo do ar.
//
// Puro, sem I/O e sem QML: o node testa isto direto e a shell importa o
// mesmo arquivo, entao os dois nunca discordam sobre o que e valido.

import { colorForRole } from "./palette.mjs";

// A lista fechada da decisao 3.4b. Uma face nao pode inventar controle
// fora dela; quando precisar de mais, usa o escape da 3.4 (trazer tela
// propria), que e outro passo e tem limites proprios.
export const CONTROL_KINDS = ["toggle", "number", "choice", "text", "role"];

// A unidade de um `number` (3.4b). Existe porque a 2b.4 diz que o minimo
// em px e declarado pela face: um numero sem unidade viraria px cravado e
// furaria o modelo de celulas num monitor com fator diferente.
export const NUMBER_UNITS = ["plain", "cell", "px"];

// Os papeis de cor da 3.4c, provisorios ate o bloco de Appearance existir.
// Uma face nomeia o papel, nunca a cor.
export const COLOR_ROLES = ["primary", "accent", "surface", "surfaceAlt", "text", "textMuted", "border"];

// Teto do `text`. A shell impoe, a face nao escolhe: uma opcao de texto e
// rotulo, nao campo de documento, e sem teto um valor absurdo iria parar no
// config.json e na tela.
export const TEXT_MAX_LENGTH = 120;

function isPlainObject(value) {
    return typeof value === "object" && value !== null && !Array.isArray(value);
}

function isFiniteNumber(value) {
    return typeof value === "number" && Number.isFinite(value);
}

// Uma chave de opcao e identificador, nao texto livre: ela vira nome de
// campo no config.json e precisa ser estavel e previsivel.
function isValidKey(key) {
    return typeof key === "string" && /^[a-zA-Z][a-zA-Z0-9]*$/.test(key);
}

// Devolve uma string de erro, ou null se a DECLARACAO serve. Repare que
// nada aqui olha para o valor guardado: isto valida o que a face pediu,
// `validateOptionValue` valida o que o usuario escolheu.
export function validateOptionDeclaration(declaration) {
    if (!isPlainObject(declaration)) return "a declaracao de opcao precisa ser um objeto";
    if (!isValidKey(declaration.key)) {
        return `chave invalida: ${JSON.stringify(declaration.key)} (letras e numeros, comecando por letra)`;
    }
    if (!CONTROL_KINDS.includes(declaration.kind)) {
        return `controle "${declaration.kind}" nao existe (os da decisao 3.4b sao: ${CONTROL_KINDS.join(", ")})`;
    }
    if (typeof declaration.title !== "string" || declaration.title.trim() === "") {
        return `a opcao "${declaration.key}" precisa de um title, que e o que o usuario le`;
    }

    if (declaration.kind === "number") {
        if (!isFiniteNumber(declaration.min) || !isFiniteNumber(declaration.max)) {
            return `a opcao "${declaration.key}" e number e precisa de min e max`;
        }
        if (declaration.min >= declaration.max) {
            return `a opcao "${declaration.key}": min precisa ser menor que max`;
        }
        if (declaration.step !== undefined && (!isFiniteNumber(declaration.step) || declaration.step <= 0)) {
            return `a opcao "${declaration.key}": step precisa ser um numero maior que zero`;
        }
        if (declaration.unit !== undefined && !NUMBER_UNITS.includes(declaration.unit)) {
            return `a opcao "${declaration.key}": unidade "${declaration.unit}" nao existe (${NUMBER_UNITS.join(", ")})`;
        }
    }

    if (declaration.kind === "choice") {
        if (!Array.isArray(declaration.choices) || declaration.choices.length < 2) {
            return `a opcao "${declaration.key}" e choice e precisa de pelo menos duas escolhas`;
        }
        for (const choice of declaration.choices) {
            if (!isPlainObject(choice) || typeof choice.value !== "string" || typeof choice.title !== "string") {
                return `a opcao "${declaration.key}": cada escolha precisa ser { value, title }, os dois texto`;
            }
        }
        const values = declaration.choices.map((choice) => choice.value);
        if (new Set(values).size !== values.length) {
            return `a opcao "${declaration.key}" repete um value entre as escolhas`;
        }
    }

    const fallback = declaration.default;
    if (fallback === undefined) return `a opcao "${declaration.key}" precisa de um default`;
    const badDefault = validateOptionValue(declaration, fallback);
    if (badDefault) return `a opcao "${declaration.key}": o default nao serve — ${badDefault}`;

    return null;
}

// Devolve uma string de erro, ou null se o VALOR serve para aquela
// declaracao. E aqui que a shell impoe o que a face so sugeriu.
export function validateOptionValue(declaration, value) {
    switch (declaration.kind) {
    case "toggle":
        return typeof value === "boolean" ? null : "precisa ser true ou false";
    case "number": {
        if (!isFiniteNumber(value)) return "precisa ser um numero";
        if (value < declaration.min || value > declaration.max) {
            return `precisa estar entre ${declaration.min} e ${declaration.max}`;
        }
        return null;
    }
    case "choice": {
        if (typeof value !== "string") return "precisa ser texto";
        const values = (declaration.choices ?? []).map((choice) => choice.value);
        return values.includes(value) ? null : `precisa ser uma de: ${values.join(", ")}`;
    }
    case "text": {
        if (typeof value !== "string") return "precisa ser texto";
        return value.length <= TEXT_MAX_LENGTH ? null : `passa de ${TEXT_MAX_LENGTH} caracteres`;
    }
    case "role":
        return COLOR_ROLES.includes(value) ? null : `precisa ser um papel de cor: ${COLOR_ROLES.join(", ")}`;
    default:
        return `controle "${declaration.kind}" nao existe`;
    }
}

// Separa as declaracoes boas das ruins em vez de recusar a face inteiro
// (3.4d). Quem chama desenha as boas e mostra as ruins como aviso: um meta
// mal escrito custa aquela opcao, nao a shell.
export function partitionSchema(schema) {
    const accepted = [];
    const rejected = [];
    const seen = new Set();
    for (const declaration of Array.isArray(schema) ? schema : []) {
        const error = validateOptionDeclaration(declaration);
        if (error) {
            rejected.push({ declaration: declaration, error: error });
        } else if (seen.has(declaration.key)) {
            rejected.push({ declaration: declaration, error: `a chave "${declaration.key}" aparece duas vezes` });
        } else {
            seen.add(declaration.key);
            accepted.push(declaration);
        }
    }
    return { accepted: accepted, rejected: rejected };
}

// So as declaracoes que passaram. E o que a tela monta e o que a face
// recebe.
export function usableSchema(schema) {
    return partitionSchema(schema).accepted;
}

// Os valores que a face de fato recebe: o default de cada opcao declarada,
// sobrescrito pelo que estiver guardado - e so pelo que for valido. Um
// valor guardado que nao serve mais (a face mudou o min, a escolha sumiu)
// cai no default em vez de chegar torto à face.
//
// A face nunca ve uma chave que ele nao declarou: o que estiver guardado a
// mais fica no config.json, intocado, e simplesmente nao e entregue. E o
// que deixa a 4.4 funcionar sem a face precisar saber dela.
export function resolveOptions(schema, stored) {
    const values = {};
    const saved = isPlainObject(stored) ? stored : {};
    for (const declaration of usableSchema(schema)) {
        const value = saved[declaration.key];
        values[declaration.key] = (value !== undefined && validateOptionValue(declaration, value) === null)
            ? value
            : declaration.default;
    }
    return values;
}

// As opcoes guardadas por face numa instancia de widget (decisao 4.4):
// { "<face>": { <chave>: <valor> } }. Guardar por nome de face e o que
// faz "trocar de face e voltar" nao perder nada - as opcoes da face
// antigo continuam ali, em silencio, debaixo do nome dele.
export function storedOptionsFor(widget, face) {
    const all = isPlainObject(widget?.options) ? widget.options : {};
    return isPlainObject(all[face]) ? all[face] : {};
}

// A instancia com UMA opcao mudada, sem tocar nas das outras faces.
// Object.assign, e nao spread de objeto: o motor de JS que o QML usa para
// estes .mjs nao aceita `{ ...obj }` (ver core/grid.mjs).
export function withOption(widget, face, key, value) {
    const all = isPlainObject(widget.options) ? widget.options : {};
    const mine = isPlainObject(all[face]) ? all[face] : {};
    const patch = {};
    patch[key] = value;
    const nextFace = Object.assign({}, mine, patch);
    const nextAll = Object.assign({}, all);
    nextAll[face] = nextFace;
    return Object.assign({}, widget, { options: nextAll });
}

// O que a face de fato recebe no canal `options`: os valores resolvidos,
// com todo papel de cor JA TRADUZIDO em cor pela paleta. A face nunca ve
// o nome do papel nem escolhe a cor - ele pede "a cor de destaque" no meta
// e recebe uma cor pronta. E o que deixa o bloco de Appearance trocar a
// shell inteira sem tocar em face nenhum (3.4c), e e a 3.4d outra vez: o
// face descreve, a shell decide.
export function resolveFaceOptions(schema, stored) {
    const values = resolveOptions(schema, stored);
    for (const declaration of usableSchema(schema)) {
        if (declaration.kind === "role") {
            values[declaration.key] = colorForRole(values[declaration.key]);
        }
    }
    return values;
}
