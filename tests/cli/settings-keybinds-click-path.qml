import QtQuick
import "../../widgets/keybinds-editor"

// 0.507 criterion 1's click path, same model as
// settings-autohide-click-path.qml: clicking the consent chip in the built
// Panel reaches config.json (via the real cli/vtnc), without ever touching
// anything under ~/.config/hypr — that only happens in the running shell,
// not here. The widget starts with no consent given, so the chip's own
// label is literally "off".
Item {
    id: harness

    KeybindsEditor {
        id: editor
        width: 600
        height: 300
        widgetConfig: ({})
    }

    function isMouseArea(obj) {
        return obj && obj.toString().indexOf("QQuickMouseArea") === 0;
    }

    function labelOf(chip) {
        for (let i = 0; i < chip.children.length; i++) {
            const child = chip.children[i];
            if (child && child.text !== undefined)
                return "" + child.text;
        }
        return "";
    }

    function findChipMouseArea(item, wanted) {
        if (!item || !item.children)
            return null;
        for (let i = 0; i < item.children.length; i++) {
            const child = item.children[i];
            if (isMouseArea(child) && labelOf(item) === wanted)
                return child;
            const found = findChipMouseArea(child, wanted);
            if (found)
                return found;
        }
        return null;
    }

    Timer {
        running: true
        interval: 400
        onTriggered: {
            const area = harness.findChipMouseArea(editor, "off");
            if (!area) {
                console.warn("KEYBINDSCLICKPATH: no chip labelled off was found");
                Qt.exit(2);
                return;
            }
            console.info("KEYBINDSCLICKPATH: clicking the off chip");
            area.clicked(null);
            exitTimer.start();
        }
    }

    Timer {
        id: exitTimer
        interval: 800
        onTriggered: Qt.exit(0)
    }
}
