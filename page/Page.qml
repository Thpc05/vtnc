import QtQuick
import "../widgets/square"
import "../widgets/clock"
import "../widgets/island-editor"
import "../widgets/autohide-settings"
import "../widgets/keybinds-editor"
import "../widgets/pages-editor"
import "../widgets/not-built"

// A page: a reusable group of widget instances with its own grid (decision
// 1b.0 / 1b.3 / 6.1). The page owns the widget instances — swap which page
// an island wears and its widgets go with it.
Item {
    id: root

    required property var pageConfig // { grid: {cols, rows}, widgets: [{type, style, cell:{x,y,w,h}}] }
    required property real cellPx

    Repeater {
        model: root.pageConfig.widgets ?? []

        delegate: Loader {
            required property var modelData

            x: (modelData.cell?.x ?? 0) * root.cellPx
            y: (modelData.cell?.y ?? 0) * root.cellPx
            width: (modelData.cell?.w ?? 1) * root.cellPx
            height: (modelData.cell?.h ?? 1) * root.cellPx

            // Adding a type is one case here, nothing else in this file
            // (decision 3.1 — type/style come from third parties too, Page
            // can't know their names in advance beyond this list).
            sourceComponent: {
                switch (modelData.type) {
                case "vtnc.square": return squareComponent;
                case "vtnc.clock": return clockComponent;
                case "vtnc.island-editor": return islandEditorComponent;
                case "vtnc.autohide-settings": return autohideSettingsComponent;
                case "vtnc.keybinds-editor": return keybindsEditorComponent;
                case "vtnc.pages-editor": return pagesEditorComponent;
                case "vtnc.not-built": return notBuiltComponent;
                default: return null;
                }
            }

            onLoaded: {
                item.widgetConfig = modelData;
            }
        }
    }

    Component {
        id: squareComponent
        Square {}
    }

    Component {
        id: clockComponent
        Clock {}
    }

    Component {
        id: islandEditorComponent
        IslandEditor {}
    }

    Component {
        id: autohideSettingsComponent
        AutohideSettings {}
    }

    Component {
        id: pagesEditorComponent
        PagesEditor {}
    }

    Component {
        id: keybindsEditorComponent
        KeybindsEditor {}
    }

    Component {
        id: notBuiltComponent
        NotBuilt {}
    }
}
