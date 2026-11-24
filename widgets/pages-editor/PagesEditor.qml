import QtQuick
import "../../core"
import "../../core/widget-catalog.mjs" as Catalog
import "./styles/panel"

// O type: vtnc.pages-editor. A pagina Pages da Settings (0.508).
//
// Decisao 8.2: o widget so existe dentro de uma page, e e aqui que ele se
// edita. Decisao 6.1: as instancias pertencem a page, entao mexer numa page
// muda TODAS as islands que a usam, ao vivo - isso e intencional, nao efeito
// colateral, e e por isso que nao ha nada aqui tentando isolar uma island da
// outra.
//
// Le Config diretamente e nao escreve nada por conta propria: toda edicao
// vira uma chamada da CLI por CliRunner (decisao 6.3).
Item {
    id: root

    property var widgetConfig: ({})

    readonly property string styleName: widgetConfig.style ?? "panel"
    readonly property var pages: Config.data.pages ?? ({})
    readonly property var pageNames: Object.keys(root.pages).sort()

    // A escolha EXPLICITA do usuario, e so ela. Vazio quer dizer "nao
    // escolhi nada ainda", nao "nenhuma page".
    property string chosenPage: ""

    // A page que o editor esta de fato mostrando. E uma ligacao, nao estado
    // montado no Component.onCompleted: quando o editor nasce, o Config
    // ainda pode nao ter lido o arquivo, e qualquer inicializacao imperativa
    // aqui corre cedo demais e deixa o editor preso no vazio (foi o que o
    // settings-pages-click-path.sh pegou). Como ligacao, ela tambem resolve
    // de graca o caso da page aberta ser apagada: some da config, e o editor
    // cai na primeira que sobrou no mesmo quadro.
    readonly property string selectedPage: (root.chosenPage !== "" && root.pages[root.chosenPage])
        ? root.chosenPage
        : (root.pageNames.length > 0 ? root.pageNames[0] : "")

    readonly property var selected: root.pages[root.selectedPage] ?? null
    readonly property var selectedWidgets: (root.selected ? root.selected.widgets : []) ?? []
    readonly property var catalog: Catalog.WIDGET_CATALOG

    function selectPage(name) {
        root.chosenPage = name;
    }

    function createPage(name) {
        const trimmed = (name ?? "").trim();
        if (trimmed === "") return;
        CliRunner.run(["page", trimmed, "create"]);
        root.chosenPage = trimmed;
    }

    function deletePage(name) {
        CliRunner.run(["page", name, "delete"]);
    }

    function writeWidgets(nextWidgets) {
        if (root.selectedPage === "") return;
        CliRunner.run(["page", root.selectedPage, "set", "widgets", JSON.stringify(nextWidgets)]);
    }

    function setGrid(cols, rows) {
        if (root.selectedPage === "") return;
        CliRunner.run(["page", root.selectedPage, "set", "grid",
                       JSON.stringify({ cols: Math.max(1, cols), rows: Math.max(1, rows) })]);
    }

    function nudgeGrid(axis, delta) {
        const grid = (root.selected ? root.selected.grid : null) ?? { cols: 10, rows: 4 };
        const cols = axis === "cols" ? (grid.cols ?? 10) + delta : (grid.cols ?? 10);
        const rows = axis === "rows" ? (grid.rows ?? 4) + delta : (grid.rows ?? 4);
        root.setGrid(cols, rows);
    }

    // O type novo nasce no canto com o tamanho que o catalogo sugere. Sem um
    // padrao o widget nasceria 0x0, invisivel, e o usuario acharia que o
    // botao nao fez nada.
    function addWidget(type) {
        const entry = Catalog.catalogEntry(type);
        if (!entry) return;
        const next = root.selectedWidgets.slice();
        next.push({
            type: type,
            cell: { x: 0, y: 0, w: entry.defaultCell.w, h: entry.defaultCell.h },
        });
        root.writeWidgets(next);
    }

    function removeWidget(index) {
        const next = root.selectedWidgets.slice();
        next.splice(index, 1);
        root.writeWidgets(next);
    }

    // Object.assign, nao spread de objeto: nem o motor de JS do QML nem o
    // que carrega os .mjs aceitam `{ ...obj }` (ver core/grid.mjs).
    function nudgeCell(index, field, delta) {
        const next = root.selectedWidgets.map(function (widget, i) {
            if (i !== index) return widget;
            const cell = widget.cell ?? { x: 0, y: 0, w: 1, h: 1 };
            const floor = (field === "w" || field === "h") ? 1 : 0;
            const patch = {};
            patch[field] = Math.max(floor, (cell[field] ?? floor) + delta);
            return Object.assign({}, widget, { cell: Object.assign({}, cell, patch) });
        });
        root.writeWidgets(next);
    }

    Loader {
        anchors.fill: parent
        sourceComponent: {
            switch (root.styleName) {
            case "panel": return panelStyle;
            default: return panelStyle;
            }
        }
    }

    Component {
        id: panelStyle
        Panel {
            pageNames: root.pageNames
            selectedPage: root.selectedPage
            selectedGrid: (root.selected ? root.selected.grid : null) ?? ({ cols: 10, rows: 4 })
            widgets: root.selectedWidgets
            catalog: root.catalog
            selectPage: root.selectPage
            createPage: root.createPage
            deletePage: root.deletePage
            nudgeGrid: root.nudgeGrid
            addWidget: root.addWidget
            removeWidget: root.removeWidget
            nudgeCell: root.nudgeCell
        }
    }
}
