// O controle global de autohide dentro da Settings (decisao 8.3 — a
// Settings e feita de widgets de verdade). Escreve so pela CLI.
export default {
    type: "vtnc.autohide-settings",
    title: "Autohide settings",
    services: [],
    defaultStyle: "panel",
    provides: [
        { name: "distance", kind: "int", doc: "A distancia global em celulas que revela uma island escondida (12.4)." },
        { name: "nudgeDistance", kind: "var", doc: "Funcao (delta) que soma ou subtrai celulas da distancia, pela CLI." },
    ],
};
