import QtQuick
import QtQuick.Window
import "../core"
import "../page"

// The Settings: a plain Hyprland window, not a layer-shell surface
// (decision 1d.6) — it follows normal app placement and dies on
// super+q, unlike an island. Verifiable: it shows up in `hyprctl clients`,
// never in `hyprctl layers`.
//
// The "casca" here is this file: the window frame and the sidebar
// (decision 8.4 — navigation only, no search). The content for each page
// is a real Page with real widgets (decision 8.3); Islands is the one
// built end to end for 0.503, the other nine say so.
Window {
    id: root

    title: "vtnc Settings"
    width: 720
    height: 480
    visible: true
    color: "#1b1b1b"

    // The ten Settings pages (decision 8.1); Islands (0.503) and Keybinds
    // (0.507) are built, the rest still say so (vtnc.not-built).
    readonly property var pageNames: [
        "Appearance", "Islands", "Pages", "Monitors", "Keybinds",
        "Services", "Extensions", "Dependencies", "Presets", "About",
    ]
    property string currentPage: "Islands"

    // A fixed cell size for the Settings content — it isn't anchored to any
    // monitor, so the screen grid's base-cell-times-factor math (core/grid.mjs)
    // doesn't apply here; this is just a convenient unit for laying out
    // fixed-size panels inside an ordinary window.
    readonly property real cellPx: 20
    readonly property int contentCols: 28

    function pageConfigFor(name) {
        if (name === "Islands") {
            const islands = Config.data.islands ?? [];
            const rowsPerIsland = 12;
            const globalRows = 3;
            return {
                grid: { cols: root.contentCols, rows: globalRows + islands.length * rowsPerIsland },
                widgets: [
                    // The one autohide knob that isn't per-island (decision
                    // 12.4): shown once, above every island's own editor.
                    { type: "vtnc.autohide-settings", cell: { x: 0, y: 0, w: root.contentCols, h: globalRows - 1 } },
                    ...islands.map((island, index) => ({
                        type: "vtnc.island-editor",
                        islandName: island.name,
                        cell: { x: 0, y: globalRows + index * rowsPerIsland, w: root.contentCols, h: rowsPerIsland - 1 },
                    })),
                ],
            };
        }
        if (name === "Keybinds") {
            const keybindRows = ((Config.data.hyprland ?? {}).keybinds ?? []).length;
            // 8 células pagam o cabeçalho fixo (consentimento, as duas linhas
            // da instrução do `require`, os rótulos das colunas e o botão de
            // acrescentar); cada keybind come 2, que é a linha de 28 px mais o
            // espaçamento. Com menos que isso o painel fica curto e as linhas
            // vazam para fora dele — foi o que a camada 4 pegou.
            const rows = 8 + 2 * keybindRows;
            return {
                grid: { cols: root.contentCols, rows: rows },
                widgets: [
                    { type: "vtnc.keybinds-editor", cell: { x: 0, y: 0, w: root.contentCols, h: rows } },
                ],
            };
        }
        return {
            grid: { cols: root.contentCols, rows: 6 },
            widgets: [
                { type: "vtnc.not-built", pageName: name, cell: { x: 0, y: 0, w: root.contentCols, h: 6 } },
            ],
        };
    }

    Row {
        anchors.fill: parent

        Rectangle {
            id: sidebar
            width: 160
            height: parent.height
            color: "#111111"

            Column {
                anchors.fill: parent

                Repeater {
                    model: root.pageNames

                    delegate: Rectangle {
                        id: entry
                        required property string modelData

                        width: sidebar.width
                        height: 36
                        color: modelData === root.currentPage ? "#3a6ea5" : "transparent"

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            text: entry.modelData
                            color: "white"
                            font.pixelSize: 13
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.currentPage = entry.modelData
                        }
                    }
                }
            }
        }

        Page {
            width: root.width - sidebar.width
            height: root.height
            cellPx: root.cellPx
            pageConfig: root.pageConfigFor(root.currentPage)
        }
    }
}
