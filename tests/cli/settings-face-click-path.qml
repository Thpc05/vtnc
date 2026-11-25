import QtQuick
import "../../modules/pages-editor"

// O caminho de clique do critério 4 da 0.509: clicar o chip "Compact" na
// linha de face de um widget tem de chegar ao config.json pelo cli/vtnc
// real. Mesmo molde do settings-pages-click-path.qml — o que muda é o chip
// procurado e o que se espera na configuração depois.
//
// O chip de face é o mais frágil de achar dos que temos: o rótulo é o
// TÍTULO da face ("Compact"), que vem do meta pelo registro, e não um
// texto escrito no QML do painel. Se o registro deixar de ser lido, o chip
// simplesmente não existe e o teste reprova por não encontrá-lo — que é
// exatamente o que se quer saber.
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
            const area = harness.findChipMouseArea(editor, "Compact");
            if (!area) {
                console.warn("FACECLICKPATH: no chip labelled Compact was found");
                Qt.exit(2);
                return;
            }
            console.info("FACECLICKPATH: selectedPage=[" + editor.selectedPage + "] pages=[" + editor.pageNames.join(",") + "]");
            console.info("FACECLICKPATH: clicking the compact face chip");
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
