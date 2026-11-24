// A pagina Keybinds da Settings (0.507). Nunca escreve no disco do
// Hyprland por conta propria: tudo passa pela CLI, e a geracao do Lua so
// acontece com o consentimento ligado (decisao 10.3b).
export default {
    type: "vtnc.keybinds-editor",
    title: "Keybinds editor",
    services: [],
    defaultStyle: "panel",
    provides: [
        { name: "consentGiven", kind: "bool", doc: "Se o usuario autorizou o vtnc a escrever sob ~/.config/hypr/vtnc (10.3b)." },
        { name: "keybinds", kind: "var", doc: "A lista de keybinds: { key, commands, enabled, description } (7.5)." },
        { name: "setConsent", kind: "var", doc: "Funcao (bool) que liga ou desliga o consentimento, pela CLI." },
        { name: "addKeybind", kind: "var", doc: "Funcao () que acrescenta um keybind vazio ao fim da lista." },
        { name: "removeKeybind", kind: "var", doc: "Funcao (index) que tira um keybind da lista." },
        { name: "updateKeybind", kind: "var", doc: "Funcao (index, campo, valor) que muda um campo de um keybind." },
    ],
};
