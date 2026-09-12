import QtQuick
import "../Config"

// ═══════════════════════════════════════════
//  SETTING GROUP — Um card de ajustes, com título em cima.
//  As linhas são filhas diretas e empilham sozinhas.
// ═══════════════════════════════════════════
Column {
    id: root

    property string title: ""
    default property alias rows: linhas.data

    width: parent ? parent.width : 0
    spacing: 8

    Text {
        text: root.title
        visible: root.title !== ""
        color: Theme.textMuted
        font { family: Theme.fontDisplay; pixelSize: 11; weight: 600 }
    }

    Rectangle {
        width: parent.width
        // O card mede o conteúdo; não tem altura própria
        height: linhas.implicitHeight + Theme.cardPadding * 2
        radius: Theme.radiusCard
        color: Theme.card
        border.width: Theme.borderWidth
        border.color: Theme.border

        Column {
            id: linhas

            anchors.fill: parent
            anchors.margins: Theme.cardPadding
            spacing: 4
        }
    }
}
