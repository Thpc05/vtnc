// Descreve o style (decisao 19.1), e desde a 0.509 e lido de verdade.
// `type` e o que diz a que type este style pertence (decisao 3.5: um style
// pertence a um unico type) — e dele que o registro deriva a lista de
// styles de cada type, para a lista nao existir escrita duas vezes.
// `component` e o arquivo QML que o type carrega para vestir este style.
export default {
    style: "compact",
    type: "vtnc.clock",
    title: "Compact",
    component: "Compact.qml",
    // O `showSeconds` existia como codigo: o style cortava a string em
    // time.slice(0, 5). Era uma opcao disfarcada, e agora e uma opcao.
    options: [
        { key: "showSeconds", kind: "toggle", title: "Show seconds", default: false },
        { key: "fill", kind: "role", title: "Pill colour", default: "accent" },
    ],
};
