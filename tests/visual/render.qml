import QtQuick
import QtQuick.Window
import "../../page"

// Renders one page to a PNG, offscreen, with no compositor: the "looked
// at" layer (decision 17.2) doesn't need layer-shell, only QtQuick's own
// grabToImage. 0.51 has no light/dark theming yet, so there's one render,
// not a pair.
Window {
    width: 400
    height: 200
    visible: true

    Page {
        id: page
        anchors.fill: parent
        cellPx: 8
        pageConfig: {
            "grid": { "cols": 10, "rows": 4 },
            "widgets": [
                { "type": "vtnc.square", "style": "default", "text": "square", "cell": { "x": 1, "y": 1, "w": 6, "h": 4 } }
            ]
        }
    }

    Component.onCompleted: {
        Qt.callLater(function () {
            page.grabToImage(function (result) {
                const ok = result.saveToFile(Qt.application.arguments[1]);
                Qt.exit(ok ? 0 : 1);
            });
        });
    }
}
