import QtQuick
import "../widgets/square"

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

            // 0.51 has exactly one type ("vtnc.square"); the loader is here
            // so a second type doesn't require touching Page.qml, only this
            // one switch (decision 3.1 — type/style come from third parties
            // too, Page can't know their names in advance beyond this list).
            sourceComponent: {
                switch (modelData.type) {
                case "vtnc.square": return squareComponent;
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
}
