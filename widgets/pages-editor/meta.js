// O widget da pagina Pages da Settings (0.508). Decisao 8.2: editar widget
// acontece dentro do editor de Pages, e o widget so existe dentro de uma
// page. Le core/Config.qml e escreve so por core/CliRunner.qml, a mesma
// fronteira dos outros controles da Settings (decisao 6.3).
export default {
    type: "vtnc.pages-editor",
    title: "Pages editor",
    services: [],
    styles: ["panel"],
};
