import QtQuick
import "../../widgets/island-editor"

// 0.504 criterion 5, modeled directly on the coordinator's
// settings-click-path.sh: not "setGap reaches config.json" (settings-write-
// boundary.sh already proves the module-to-CLI boundary in general), but
// "clicking the gap stepper's + button calls it". Walks the built item
// tree to the Stepper labelled "gap", finds its "+" MouseArea by name
// (decrementButton/incrementButton, as Panel.qml's Stepper declares them),
// and emits its clicked signal: MouseArea -> Stepper.incremented ->
// IslandEditor.nudgeGap -> CliRunner -> cli/vtnc -> config.json.
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

    // A Stepper's "+" button is a Rectangle whose own Text child reads "+"
    // literally (Panel.qml has no other way to tell it from "-" from the
    // outside — no objectName is set, only a QML id, which isn't visible
    // to JS introspection).
    function isPlusButton(item) {
        if (!item || !item.children)
            return false;
        for (let i = 0; i < item.children.length; i++) {
            const child = item.children[i];
            if (child && child.text !== undefined && ("" + child.text) === "+")
                return true;
        }
        return false;
    }

    // The Stepper labelled "gap:" is a Row whose own Text child reads
    // "gap:"; find it, then its "+" Rectangle's MouseArea.
    function findGapIncrementArea(item) {
        if (!item || !item.children)
            return null;
        let hasGapLabel = false;
        let incrementArea = null;
        for (let i = 0; i < item.children.length; i++) {
            const child = item.children[i];
            if (child && child.text !== undefined && ("" + child.text) === "gap:")
                hasGapLabel = true;
            if (isPlusButton(child)) {
                for (let j = 0; j < child.children.length; j++) {
                    if (isMouseArea(child.children[j]))
                        incrementArea = child.children[j];
                }
            }
        }
        if (hasGapLabel && incrementArea)
            return incrementArea;
        for (let i = 0; i < item.children.length; i++) {
            const found = harness.findGapIncrementArea(item.children[i]);
            if (found)
                return found;
        }
        return null;
    }

    Timer {
        running: true
        interval: 400
        onTriggered: {
            const area = harness.findGapIncrementArea(editor);
            if (!area) {
                console.warn("GAPCLICKPATH: no gap stepper's + button was found");
                Qt.exit(2);
                return;
            }
            console.info("GAPCLICKPATH: clicking the gap + button");
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
