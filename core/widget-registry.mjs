// O registro dos types e dos styles (0.509). A fonte unica de quem e
// quem: o node le isto nos testes e o QML le isto na shell, entao os dois
// nao podem discordar.
//
// Ate a 0.508 os `meta.js` eram decoracao - nada no codigo os abria, e a
// lista de styles de um type vivia escrita duas vezes, no meta e num
// `switch` dentro do QML do proprio type. A 3.5b so vale alguma coisa se o
// que o type publica estiver num lugar que o codigo le e um teste confere;
// e isso que este arquivo faz.
//
// Medido antes de escrever: um .mjs consegue importar outro .mjs (ou .js)
// de outra pasta de dentro do QML - probei com `qml6` e funciona. Era a
// duvida que decidia se o schema podia morar junto de cada style ou teria
// de virar uma lista central. Mora junto.
//
// O que ainda NAO e: um catalogo automatico que varre pastas e deixa uma
// extensao de terceiro se apresentar sozinha (3b/4.x). Os imports abaixo
// sao escritos a mao, um a um. O passo que trouxer extensao de verdade
// troca estas linhas por varredura; nada mais precisa mudar, porque todo o
// resto do codigo ja pergunta ao registro, nao aos arquivos.

import clockType from "../widgets/clock/meta.js";
import squareType from "../widgets/square/meta.js";
import islandEditorType from "../widgets/island-editor/meta.js";
import autohideSettingsType from "../widgets/autohide-settings/meta.js";
import keybindsEditorType from "../widgets/keybinds-editor/meta.js";
import pagesEditorType from "../widgets/pages-editor/meta.js";
import notBuiltType from "../widgets/not-built/meta.js";

import clockDigital from "../widgets/clock/styles/digital/meta.js";
import clockCompact from "../widgets/clock/styles/compact/meta.js";
import squareDefault from "../widgets/square/styles/default/meta.js";
import islandEditorPanel from "../widgets/island-editor/styles/panel/meta.js";
import autohideSettingsPanel from "../widgets/autohide-settings/styles/panel/meta.js";
import keybindsEditorPanel from "../widgets/keybinds-editor/styles/panel/meta.js";
import pagesEditorPanel from "../widgets/pages-editor/styles/panel/meta.js";
import notBuiltPlaceholder from "../widgets/not-built/styles/placeholder/meta.js";

export const TYPE_METAS = [
    clockType,
    squareType,
    islandEditorType,
    autohideSettingsType,
    keybindsEditorType,
    pagesEditorType,
    notBuiltType,
];

export const STYLE_METAS = [
    clockDigital,
    clockCompact,
    squareDefault,
    islandEditorPanel,
    autohideSettingsPanel,
    keybindsEditorPanel,
    pagesEditorPanel,
    notBuiltPlaceholder,
];

// A pasta de cada type, derivada do nome: "vtnc.island-editor" mora em
// widgets/island-editor. O prefixo da fonte (decisao 3.1) e o que vem
// antes do ponto; hoje so existe "vtnc", e quando existir extensao de
// terceiro e aqui que a pasta deixa de ser widgets/ e passa a ser a do
// autor.
export function typeFolder(type) {
    const dot = type.indexOf(".");
    return dot === -1 ? type : type.slice(dot + 1);
}

export function typeMeta(type) {
    return TYPE_METAS.find((meta) => meta.type === type) ?? null;
}

// Quais styles um type tem. Derivado do `type` declarado por cada style
// (decisao 3.5), nunca de uma lista no meta do type: a lista escrita duas
// vezes era justamente o que podia discordar em silencio.
export function stylesOf(type) {
    return STYLE_METAS.filter((meta) => meta.type === type);
}

export function styleMeta(type, style) {
    return STYLE_METAS.find((meta) => meta.type === type && meta.style === style) ?? null;
}

// O style que a instancia veste quando nao escolheu nenhum. Vem do meta do
// type - um nome so, nao uma lista, entao nao e duplicacao.
export function defaultStyleOf(type) {
    return typeMeta(type)?.defaultStyle ?? null;
}

// O caminho do QML do style, relativo a pasta do type - que e exatamente
// de onde o QML do type carrega. Devolve null para um style que nao existe
// naquele type, e quem chama decide o que fazer: o QML cai no defaultStyle.
export function styleComponentPath(type, style) {
    const meta = styleMeta(type, style);
    return meta ? `styles/${meta.style}/${meta.component}` : null;
}

// O mesmo caminho, ja resolvido para o style que vale: o pedido, se ele
// existir neste type, senao o padrao do type. E o que o QML do type chama,
// para nao ter de repetir essa queda em sete arquivos.
export function resolvedStylePath(type, style) {
    return styleComponentPath(type, style) ?? styleComponentPath(type, defaultStyleOf(type));
}

// A interface que o type publica aos seus styles (decisao 3.5b). Cada
// entrada e { name, kind, doc }. Um teste le o QML de cada style e reprova
// se ele exigir algo que nao esteja aqui.
export function providesOf(type) {
    return typeMeta(type)?.provides ?? [];
}

// `options` nao entra em `provides`: e o canal que o vtnc da a todo style,
// nao algo que este ou aquele type inventou. O teste da 3.5b pula este
// nome por isso. (O conteudo das options e a 3.4, que espera a oq-8-5.)
export const FRAMEWORK_PROPERTIES = ["options"];

// O schema de opcoes que um style declara (decisao 3.4). Vem do meta do
// proprio style, nunca de uma lista central: e isso que deixa um style de
// terceiro trazer as suas opcoes sem tocar na Settings. Quem decide se a
// declaracao serve e core/style-schema.mjs, nao este arquivo.
export function optionSchemaOf(type, style) {
    return styleMeta(type, style)?.options ?? [];
}
