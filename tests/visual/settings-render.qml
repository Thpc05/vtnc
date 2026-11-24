import QtQuick
import Quickshell
import "../../settings"

// 0.503 acceptance criterion 6: render the Settings window open on the
// Islands page, for a human to look at — not Settings.qml's default
// pageConfig isn't touched, this just screenshots it as it opens. Needs a
// real compositor: grabToImage never calls back under
// QT_QPA_PLATFORM=offscreen (tests/README.md).
Settings {
    id: root

    // 0.507: qual página abrir, para a camada 4 poder olhar mais de uma.
    // Vazio (ou ausente) mantém o padrão da própria Settings, que é Islands —
    // é assim que a chamada da 0.503 segue funcionando sem mudar nada.
    currentPage: Quickshell.env("VTNC_RENDER_PAGE") || "Islands"

    Timer {
        running: true
        interval: 500
        onTriggered: {
            // `qs` doesn't forward trailing CLI args the way `qml6 -- ...`
            // does, so the output path travels as an env var instead —
            // the same pattern core/Paths.qml already uses for VTNC_CONFIG_DIR.
            const out = Quickshell.env("VTNC_RENDER_OUT");
            root.contentItem.grabToImage(function (result) {
                const ok = result.saveToFile(out);
                if (!ok)
                    console.warn("settings-render.qml: saveToFile failed for", out);
                Qt.exit(ok ? 0 : 1);
            });
        }
    }
}
