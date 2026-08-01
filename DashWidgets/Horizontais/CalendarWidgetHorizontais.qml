import QtQuick
import Quickshell
import "../../Components"

// ═══════════════════════════════════════════
//  CALENDAR WIDGET — calendario.
//  Idle: ícone + a data de hoje.
//  Expandido: o mês inteiro em grade, hoje em destaque.
//  Tamanhos: normal/big (default big → big, pra baixo).
// ═══════════════════════════════════════════
DashWidget {
    id: root

    name: "calendar"
    sizeIdle: "big"    // Normal, Big and Full
    sizeExpand: "big"  // Big and Full
    expandDir: "down"  // down

    SystemClock {
        id: sysClock
        precision: SystemClock.Minutes
    }

    readonly property date today: sysClock.date
    readonly property int firstDow:
        new Date(today.getFullYear(), today.getMonth(), 1).getDay()
    readonly property int daysInMonth:
        new Date(today.getFullYear(), today.getMonth() + 1, 0).getDate()

    // ── HEADER: ícone + dado (a data de hoje, à direita do ícone) ──
    Row {
        anchors.left: parent.left
        anchors.top: parent.top
        height: root.headerH
        spacing: 8

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "󰃭"
            color: root.expanded ? Theme.accent : Theme.textMuted
            font { family: Theme.fontIcon; pixelSize: 16 }
            Behavior on color { ColorAnimation { duration: Theme.hoverFade } }
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatDateTime(root.today, "ddd, d MMM")
            color: Theme.textPrimary
            font { family: Theme.fontDisplay; pixelSize: 12; weight: 600 }
        }
    }

    // ── EXPANDIDO: o mês em grade ──
    Grid {
        id: calGrid

        columns: 7
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        opacity: root.lateReveal
        visible: opacity > 0

        // Cabeçalho dos dias da semana
        Repeater {
            model: ["D", "S", "T", "Q", "Q", "S", "S"]

            Item {
                required property string modelData

                width: calGrid.width / 7
                height: 16

                Text {
                    anchors.centerIn: parent
                    text: parent.modelData
                    color: Theme.textMuted
                    font { family: Theme.fontMono; pixelSize: 9 }
                }
            }
        }

        // Dias do mês (células vazias até o 1º dia da semana)
        Repeater {
            model: root.firstDow + root.daysInMonth

            Item {
                required property int index

                readonly property int day: index - root.firstDow + 1
                readonly property bool isToday: day === root.today.getDate()

                width: calGrid.width / 7
                height: 19

                Rectangle {
                    anchors.centerIn: parent
                    width: 17
                    height: 17
                    radius: 8.5
                    color: Theme.accent
                    visible: parent.isToday && parent.day > 0
                }

                Text {
                    anchors.centerIn: parent
                    visible: parent.day > 0
                    text: parent.day
                    color: parent.isToday ? Theme.bg : Theme.textSecondary
                    font {
                        family: Theme.fontMono
                        pixelSize: 9
                        weight: parent.isToday ? 700 : 400
                    }
                }
            }
        }
    }
}
