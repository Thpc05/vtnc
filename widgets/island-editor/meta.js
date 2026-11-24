// O controle de uma island dentro da Settings (decisao 8.3 — a Settings e
// feita de pages e widgets de verdade, so nao editaveis). Le o estado vivo
// do core/Config.qml e escreve exclusivamente pela CLI (6.3).
//
// A lista `provides` e longa porque este type entrega muita coisa: e
// exatamente por isso que a 3.5b pede que ela esteja escrita. Quem for
// escrever um style novo para esta tela le daqui o que vai receber, sem
// abrir o QML do type.
export default {
    type: "vtnc.island-editor",
    title: "Island editor",
    services: [],
    defaultStyle: "panel",
    provides: [
        { name: "islandName", kind: "string", doc: "O nome da island sendo editada." },
        { name: "anchor", kind: "var", doc: "As bordas ancoradas: { top, bottom, left, right } booleanos." },
        { name: "offset", kind: "var", doc: "O deslocamento { x, y } em celulas a partir da ancora." },
        { name: "size", kind: "var", doc: "O tamanho { w, h } em celulas." },
        { name: "gap", kind: "int", doc: "O afastamento da borda, em celulas (2d.3: um numero, nunca quatro lados)." },
        { name: "islandLayer", kind: "string", doc: "A camada Wayland: background, bottom, top ou overlay." },
        { name: "pageName", kind: "string", doc: "A page que a island veste quando esta idle." },
        { name: "pageNames", kind: "var", doc: "Os nomes de todas as pages que existem, para escolher." },
        { name: "autohide", kind: "bool", doc: "Se esta island se esconde, ja resolvido contra o global (11.2c)." },
        { name: "autohideMode", kind: "string", doc: "Quando ela se esconde: always, window ou fullscreen." },
        { name: "edges", kind: "var", doc: "A lista fechada de bordas que uma ancora aceita." },
        { name: "layers", kind: "var", doc: "A lista fechada de camadas Wayland." },
        { name: "autohideModes", kind: "var", doc: "A lista fechada de modos de autohide." },
        { name: "setAnchorEdge", kind: "var", doc: "Funcao (borda, bool) que liga ou desliga uma borda da ancora." },
        { name: "nudgeOffset", kind: "var", doc: "Funcao (eixo, delta) que move a island em celulas." },
        { name: "nudgeSize", kind: "var", doc: "Funcao (eixo, delta) que cresce ou encolhe a island em celulas." },
        { name: "nudgeGap", kind: "var", doc: "Funcao (delta) que muda o afastamento da borda." },
        { name: "setLayer", kind: "var", doc: "Funcao (camada) que troca a camada Wayland da island." },
        { name: "setPage", kind: "var", doc: "Funcao (nome) que troca a page idle da island." },
        { name: "setAutohide", kind: "var", doc: "Funcao (bool) que liga ou desliga o autohide desta island." },
        { name: "setAutohideMode", kind: "var", doc: "Funcao (modo) que troca o modo de autohide desta island." },
    ],
};
