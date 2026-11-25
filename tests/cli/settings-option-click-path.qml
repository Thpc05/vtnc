import QtQuick
import "../../modules/pages-editor"

// O caminho de clique do critério 1 da 0.510: clicar o controle de uma
// OPÇÃO de face tem de chegar ao config.json pelo cli/vtnc real.
//
// Este é o mais indireto de todos os click-paths: o chip "on" não existe
// escrito em lugar nenhum. Ele aparece porque o meta da face `digital`
// declara uma opção `showSeconds` do tipo toggle, o registro entrega essa
// declaração ao editor, e o painel desenha o controle que a declaração
// pediu. Se qualquer elo dessa corrente quebrar, não há chip para clicar e
// o teste reprova por não achá-lo — que é o que se quer saber.
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
            const area = harness.findChipMouseArea(editor, "on");
            if (!area) {
                console.warn("OPTIONCLICKPATH: no chip labelled Compact was found");
                Qt.exit(2);
                return;
            }
            console.info("OPTIONCLICKPATH: selectedPage=[" + editor.selectedPage + "] pages=[" + editor.pageNames.join(",") + "]");
            console.info("OPTIONCLICKPATH: clicking the showSeconds toggle");
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
