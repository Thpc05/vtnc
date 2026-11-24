// A pagina Pages da Settings (0.508): onde um widget nasce, morre e muda
// de lugar, ja que ele so existe dentro de uma page (decisao 8.2).
export default {
    type: "vtnc.pages-editor",
    title: "Pages editor",
    services: [],
    defaultStyle: "panel",
    provides: [
        { name: "pageNames", kind: "var", doc: "Os nomes das pages que existem, em ordem." },
        { name: "selectedPage", kind: "string", doc: "A page aberta no editor; vazio quando nao ha page nenhuma." },
        { name: "selectedGrid", kind: "var", doc: "A grade { cols, rows } da page aberta." },
        { name: "widgets", kind: "var", doc: "As instancias de widget dentro da page aberta, na ordem da config." },
        { name: "catalog", kind: "var", doc: "O que da para acrescentar: { type, title, defaultCell } por entrada." },
        { name: "stylesOf", kind: "var", doc: "Funcao (type) que devolve os styles daquele type: { style, title } (3.3/3.5)." },
        { name: "styleOfWidget", kind: "var", doc: "Funcao (widget) que diz qual style a instancia veste de fato, caindo no padrao do type." },
        { name: "selectPage", kind: "var", doc: "Funcao (nome) que abre outra page no editor." },
        { name: "createPage", kind: "var", doc: "Funcao (nome) que cria uma page pela CLI." },
        { name: "deletePage", kind: "var", doc: "Funcao (nome) que apaga uma page; as islands que a usavam caem no estado empty (14.3)." },
        { name: "nudgeGrid", kind: "var", doc: "Funcao (eixo, delta) que muda cols ou rows da page aberta." },
        { name: "addWidget", kind: "var", doc: "Funcao (type) que acrescenta um widget daquele type com a celula padrao do catalogo." },
        { name: "removeWidget", kind: "var", doc: "Funcao (index) que tira um widget da page." },
        { name: "nudgeCell", kind: "var", doc: "Funcao (index, campo, delta) que muda x, y, w ou h de um widget." },
        { name: "setStyle", kind: "var", doc: "Funcao (index, style) que veste outro style naquele widget (3.3, escala de widget)." },
    ],
};
