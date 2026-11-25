// Descreve a face (decisao 19.1), e desde a 0.509 e lido de verdade.
// `module` e o que diz a que module esta face pertence (decisao 3.5: uma face
// pertence a um unico module) — e dele que o registro deriva a lista de
// faces de cada module, para a lista nao existir escrita duas vezes.
// `component` e o arquivo QML que o module carrega para vestir esta face.
export default {
    face: "compact",
    module: "vtnc.clock",
    title: "Compact",
    component: "Compact.qml",
    // O `showSeconds` existia como codigo: a face cortava a string em
    // time.slice(0, 5). Era uma opcao disfarcada, e agora e uma opcao.
    options: [
        { key: "showSeconds", kind: "toggle", title: "Show seconds", default: false },
        { key: "fill", kind: "role", title: "Pill colour", default: "accent" },
    ],
};
