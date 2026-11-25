// Descreve a face (decisao 19.1), e desde a 0.509 e lido de verdade.
// `module` e o que diz a que module esta face pertence (decisao 3.5: uma face
// pertence a um unico module) — e dele que o registro deriva a lista de
// faces de cada module, para a lista nao existir escrita duas vezes.
// `component` e o arquivo QML que o module carrega para vestir esta face.
export default {
    face: "panel",
    module: "vtnc.keybinds-editor",
    title: "Panel",
    component: "Panel.qml",
};
