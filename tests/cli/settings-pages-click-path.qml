import QtQuick
import "../../modules/pages-editor"

// O caminho de clique do critério 5 da 0.508, no mesmo molde do
// settings-keybinds-click-path.qml: clicar o chip "+ Clock" no Panel
// construído de verdade tem de chegar ao config.json pelo cli/vtnc real, e
// por mais nada. Sem compositor, sem shell, sem IPC — se o widget
// escrevesse a configuração por conta própria, este teste passaria do mesmo
// jeito, então ele vem acompanhado do settings-write-boundary.sh, que prova
// que sem o binário nada é escrito.
Item {
    id: harness

    PagesEditor {
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
            const area = harness.findChipMouseArea(editor, "+ Clock");
            if (!area) {
                console.warn("PAGESCLICKPATH: no chip labelled + Clock was found");
                Qt.exit(2);
                return;
            }
            console.info("PAGESCLICKPATH: selectedPage=[" + editor.selectedPage + "] pages=[" + editor.pageNames.join(",") + "]");
            console.info("PAGESCLICKPATH: clicking the add-clock chip");
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
