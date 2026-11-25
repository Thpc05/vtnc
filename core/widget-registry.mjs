// O registro dos modules e das faces (0.509). A fonte unica de quem e
// quem: o node le isto nos testes e o QML le isto na shell, entao os dois
// nao podem discordar.
//
// Ate a 0.508 os `meta.js` eram decoracao - nada no codigo os abria, e a
// lista de faces de um module vivia escrita duas vezes, no meta e num
// `switch` dentro do QML do proprio module. A 3.5b so vale alguma coisa se o
// que o module publica estiver num lugar que o codigo le e um teste confere;
// e isso que este arquivo faz.
//
// Medido antes de escrever: um .mjs consegue importar outro .mjs (ou .js)
// de outra pasta de dentro do QML - probei com `qml6` e funciona. Era a
// duvida que decidia se o schema podia morar junto de cada face ou teria
// de virar uma lista central. Mora junto.
//
// O que ainda NAO e: um catalogo automatico que varre pastas e deixa uma
// extensao de terceiro se apresentar sozinha (3b/4.x). Os imports abaixo
// sao escritos a mao, um a um. O passo que trouxer extensao de verdade
// troca estas linhas por varredura; nada mais precisa mudar, porque todo o
// resto do codigo ja pergunta ao registro, nao aos arquivos.

import clockModule from "../widgets/clock/meta.js";
import squareModule from "../widgets/square/meta.js";
import islandEditorModule from "../widgets/island-editor/meta.js";
import autohideSettingsModule from "../widgets/autohide-settings/meta.js";
import keybindsEditorModule from "../widgets/keybinds-editor/meta.js";
import pagesEditorModule from "../widgets/pages-editor/meta.js";
import notBuiltModule from "../widgets/not-built/meta.js";

import clockDigital from "../widgets/clock/faces/digital/meta.js";
import clockCompact from "../widgets/clock/faces/compact/meta.js";
import squareDefault from "../widgets/square/faces/default/meta.js";
import islandEditorPanel from "../widgets/island-editor/faces/panel/meta.js";
import autohideSettingsPanel from "../widgets/autohide-settings/faces/panel/meta.js";
import keybindsEditorPanel from "../widgets/keybinds-editor/faces/panel/meta.js";
import pagesEditorPanel from "../widgets/pages-editor/faces/panel/meta.js";
import notBuiltPlaceholder from "../widgets/not-built/faces/placeholder/meta.js";

export const MODULE_METAS = [
    clockModule,
    squareModule,
    islandEditorModule,
    autohideSettingsModule,
    keybindsEditorModule,
    pagesEditorModule,
    notBuiltModule,
];

export const FACE_METAS = [
    clockDigital,
    clockCompact,
    squareDefault,
    islandEditorPanel,
    autohideSettingsPanel,
    keybindsEditorPanel,
    pagesEditorPanel,
    notBuiltPlaceholder,
];

// A pasta de cada module, derivada do nome: "vtnc.island-editor" mora em
// widgets/island-editor. O prefixo da fonte (decisao 3.1) e o que vem
// antes do ponto; hoje so existe "vtnc", e quando existir extensao de
// terceiro e aqui que a pasta deixa de ser widgets/ e passa a ser a do
// autor.
export function moduleFolder(module) {
    const dot = module.indexOf(".");
    return dot === -1 ? module : module.slice(dot + 1);
}

export function moduleMeta(module) {
    return MODULE_METAS.find((meta) => meta.module === module) ?? null;
}

// Quais faces um module tem. Derivado do `module` declarado por cada face
// (decisao 3.5), nunca de uma lista no meta do module: a lista escrita duas
// vezes era justamente o que podia discordar em silencio.
export function facesOf(module) {
    return FACE_METAS.filter((meta) => meta.module === module);
}

export function faceMeta(module, face) {
    return FACE_METAS.find((meta) => meta.module === module && meta.face === face) ?? null;
}

// A face que a instancia veste quando nao escolheu nenhum. Vem do meta do
// module - um nome so, nao uma lista, entao nao e duplicacao.
export function defaultFaceOf(module) {
    return moduleMeta(module)?.defaultFace ?? null;
}

// O caminho do QML da face, relativo a pasta do module - que e exatamente
// de onde o QML do module carrega. Devolve null para uma face que nao existe
// naquele module, e quem chama decide o que fazer: o QML cai no defaultFace.
export function faceComponentPath(module, face) {
    const meta = faceMeta(module, face);
    return meta ? `faces/${meta.face}/${meta.component}` : null;
}

// O mesmo caminho, ja resolvido para a face que vale: o pedido, se ele
// existir neste module, senao o padrao do module. E o que o QML do module chama,
// para nao ter de repetir essa queda em sete arquivos.
export function resolvedFacePath(module, face) {
    return faceComponentPath(module, face) ?? faceComponentPath(module, defaultFaceOf(module));
}

// A interface que o module publica aos seus faces (decisao 3.5b). Cada
// entrada e { name, kind, doc }. Um teste le o QML de cada face e reprova
// se ele exigir algo que nao esteja aqui.
export function providesOf(module) {
    return moduleMeta(module)?.provides ?? [];
}

// `options` nao entra em `provides`: e o canal que o vtnc da a toda face,
// nao algo que este ou aquele module inventou. O teste da 3.5b pula este
// nome por isso. (O conteudo das options e a 3.4, que espera a oq-8-5.)
export const FRAMEWORK_PROPERTIES = ["options"];

// O schema de opcoes que uma face declara (decisao 3.4). Vem do meta do
// propria face, nunca de uma lista central: e isso que deixa uma face de
// terceiro trazer as suas opcoes sem tocar na Settings. Quem decide se a
// declaracao serve e core/face-schema.mjs, nao este arquivo.
export function optionSchemaOf(module, face) {
    return faceMeta(module, face)?.options ?? [];
}
