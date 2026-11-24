// O catalogo dos widgets que o usuario pode colocar numa page (0.508).
//
// Um widget so existe dentro de uma page (decisao 8.2), entao o editor de
// Pages precisa saber o que ha para oferecer. A lista vive aqui, pura e
// testavel em node, e nao no QML, para que o editor e o `page/Page.qml`
// nao possam discordar: um type que o Page nao sabe desenhar nao deve
// aparecer no menu de acrescentar.
//
// Isto NAO e o catalogo automatico por `meta.js` que a 3b/4.x pede, com
// extensoes de terceiros se apresentando sozinhas - esse e outro passo.
// Aqui a lista e escrita a mao e conferida contra o Page por teste.
export const WIDGET_CATALOG = [
    { type: "vtnc.clock", title: "Clock", defaultCell: { w: 6, h: 2 } },
    { type: "vtnc.square", title: "Square", defaultCell: { w: 2, h: 2 } },
];

// Os widgets que a propria Settings usa. A decisao 8.3 diz que a Settings e
// feita do mesmo mecanismo - pages e widgets de verdade - so que nao
// editaveis; e por isso que eles existem, e por isso que nao entram no
// catalogo que o editor oferece.
export const SETTINGS_ONLY_TYPES = [
    "vtnc.island-editor",
    "vtnc.autohide-settings",
    "vtnc.keybinds-editor",
    "vtnc.pages-editor",
    "vtnc.not-built",
];

export function catalogEntry(type) {
    return WIDGET_CATALOG.find((entry) => entry.type === type) ?? null;
}

export function isPlaceableType(type) {
    return catalogEntry(type) !== null;
}
