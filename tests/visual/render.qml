import QtQuick
import QtQuick.Window
import Quickshell
import "../../page"

// Renders one page to a PNG: the "looked at" layer (decision 17.2). It needs
// a real compositor — grabToImage never calls back under
// QT_QPA_PLATFORM=offscreen, with any render loop or scene-graph backend —
// so this runs inside the nested test session (tools/headless/nested.sh).
// 0.51 has no light/dark theming yet, so there's one render, not a pair.
//
// 0.503: Page.qml now unconditionally imports widgets/island-editor (for
// its switch case), which imports core/Config.qml — a pragma Singleton
// that only resolves under `qs`'s own runtime, not plain qml6. So this
// runs via `qs -p` now (render-check.sh), not bare qml6 like before.
Window {
    width: 400
    height: 200
    visible: true

    Page {
        id: page
        anchors.fill: parent
        cellPx: 8

        // The parentheses matter: `property: { ... }` is parsed as a code
        // block, not an object literal, and without them this file loads
        // nothing at all, silently.
        pageConfig: ({
            "grid": { "cols": 28, "rows": 4 },
            "widgets": [
                { "type": "vtnc.square", "style": "default", "text": "square", "cell": { "x": 1, "y": 1, "w": 6, "h": 4 } },
                { "type": "vtnc.clock", "style": "digital", "cell": { "x": 9, "y": 0, "w": 12, "h": 4 } },
                { "type": "vtnc.clock", "style": "compact", "cell": { "x": 23, "y": 1, "w": 5, "h": 2 } }
            ]
        })
    }

    Component.onCompleted: {
        Qt.callLater(function () {
            // `qs` doesn't forward trailing CLI args the way `qml6 -- ...`
            // did, so the output path travels as an env var instead.
            const out = Quickshell.env("VTNC_RENDER_OUT");
            page.grabToImage(function (result) {
                const ok = result.saveToFile(out);
                if (!ok)
                    console.warn("render.qml: saveToFile failed for", out);
                Qt.exit(ok ? 0 : 1);
            });
        });
    }
}
