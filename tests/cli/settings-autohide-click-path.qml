import QtQuick
import "../../widgets/island-editor"

// 0.505 criterion 5's click path, the same model as the coordinator's
// settings-click-path.sh / settings-gap-click-path.sh: not "setAutohide
// reaches config.json" (settings-write-boundary.sh already proves the
// type-to-CLI boundary in general), but "clicking the toggle in the built
// Panel actually calls it". The island starts with no autohide override
// (so it reads the global default, off), so the toggle's own label is
// literally "off" — the one chip in the whole panel with that exact text,
// since no edge/layer/page/mode is ever named "on" or "off".
Item {
    id: harness

    IslandEditor {
        id: editor
        width: 600
        height: 300
        widgetConfig: ({ islandName: "bar" })
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
                console.warn("AUTOHIDECLICKPATH: no chip labelled off was found");
                Qt.exit(2);
                return;
            }
            console.info("AUTOHIDECLICKPATH: clicking the off chip");
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
