import QtQuick
import "../Config"
import "../Island"
import "../Services"

// ═══════════════════════════════════════════
//  SESSION — paleta de sessão (bloquear · sair · suspender ·
//  reiniciar · desligar). Mesma linguagem do Tools: hover e seleção
//  são o mesmo índice, ←/→ movem, Enter dispara, Esc fecha. Ações
//  destrutivas acendem em danger.
//  As ações moram em Services/SessionService.qml.
//
//  IPC: qs -c vtnc ipc call session toggle
// ═══════════════════════════════════════════
IslandFace {
    id: root

    name: "session"
    role: "app"
    grabsKeyboard: true

    property int selIndex: 0

    contentWidth: actionsRow.implicitWidth + Theme.contentPadding * 2
    contentHeight: Config.showTips ? 64 : 48

    onActiveChanged: {
        if (active) {
            selIndex = 0
            focusTimer.restart()
        }
    }

    Timer {
        id: focusTimer
        interval: 20
        onTriggered: kb.forceActiveFocus()
    }

    function runSelected() {
        SessionService.run(SessionService.actions[selIndex].id)
        closeRequested()
    }

    // ── TECLADO ──
    Item {
        id: kb

        anchors.fill: parent
        focus: root.active

        Keys.onPressed: event => {
            switch (event.key) {
            case Qt.Key_Left:
                root.selIndex = (root.selIndex - 1 + SessionService.actions.length)
                    % SessionService.actions.length
                break
            case Qt.Key_Right:
                root.selIndex = (root.selIndex + 1) % SessionService.actions.length
                break
            case Qt.Key_Return:
            case Qt.Key_Enter:
                root.runSelected()
                break
            case Qt.Key_Escape: root.closeRequested(); break
            default: return
            }
            event.accepted = true
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 3

        Row {
            id: actionsRow

            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 5

            Repeater {
                model: SessionService.actions

                Item {
                    id: act

                    required property var modelData
                    required property int index

                    readonly property bool selected: root.selIndex === index

                    width: 30
                    height: 30

                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.radiusChip
                        color: act.selected ? Theme.hoverLayer : "transparent"
                        Behavior on color { ColorAnimation { duration: Motion.instant } }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: act.modelData.icon
                        color: act.selected
                            ? (act.modelData.danger ? Theme.danger : Theme.accent)
                            : Theme.textPrimary
                        font { family: Theme.fontIcon; pixelSize: 17 }
                        Behavior on color { ColorAnimation { duration: Motion.instant } }
                    }

                    HoverHandler {
                        onHoveredChanged: {
                            if (hovered)
                                root.selIndex = act.index
                        }
                    }
                    TapHandler {
                        onTapped: {
                            root.selIndex = act.index
                            root.runSelected()
                        }
                    }
                }
            }
        }

        // ── LEGENDA do selecionado ──
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: Config.showTips
            text: SessionService.actions[root.selIndex]?.label ?? ""
            color: Theme.textSecondary
            font { family: Theme.fontDisplay; pixelSize: 10 }
        }
    }
}
