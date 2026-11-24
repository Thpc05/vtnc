// Descreve o style (decisao 19.1), e desde a 0.509 e lido de verdade.
// `type` e o que diz a que type este style pertence (decisao 3.5: um style
// pertence a um unico type) — e dele que o registro deriva a lista de
// styles de cada type, para a lista nao existir escrita duas vezes.
// `component` e o arquivo QML que o type carrega para vestir este style.
export default {
    style: "digital",
    type: "vtnc.clock",
    title: "Digital",
    component: "Digital.qml",
    // As opcoes deste style (decisao 3.4). So os cinco controles da 3.4b, e
    // quem impoe min/max e a lista e a shell, nao este arquivo (3.4d).
    options: [
        { key: "showSeconds", kind: "toggle", title: "Show seconds", default: true },
        { key: "fontSize", kind: "number", title: "Font size", default: 20,
          min: 8, max: 72, step: 1, unit: "px" },
        { key: "align", kind: "choice", title: "Align", default: "center",
          choices: [
              { value: "left", title: "Left" },
              { value: "center", title: "Center" },
              { value: "right", title: "Right" },
          ] },
        { key: "color", kind: "role", title: "Text colour", default: "text" },
    ],
};
