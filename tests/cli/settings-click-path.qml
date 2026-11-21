import QtQuick
import "../../widgets/island-editor"

// The last inch of 0.503's criterion 3/4 that driving the type's functions
// can't reach: does clicking a control in the Panel style actually call
// them? No input injection — none of the isolated tools for it are
// installed, and ydotool goes through the kernel's uinput, which is not
// scoped to a compositor and would leak into Theo's real session. Instead
// this walks the built item tree, finds the MouseArea inside the chip
// labelled "overlay", and emits its clicked signal. That covers
// MouseArea -> Chip.activated -> IslandEditor.setLayer -> CliRunner ->
// cli/vtnc -> config.json, which is the whole chain the step claims.
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

    // The chip's own Text child is what names it on screen.
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
            const area = harness.findChipMouseArea(editor, "overlay");
            if (!area) {
                console.warn("CLICKPATH: no chip labelled overlay was found");
                Qt.exit(2);
                return;
            }
            console.info("CLICKPATH: clicking the overlay chip");
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
