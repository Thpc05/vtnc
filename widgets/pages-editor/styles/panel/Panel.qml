import QtQuick

// O unico style do vtnc.pages-editor. Tudo o que o type entrega esta
// declarado aqui (decisao 3.5b): a lista de pages, a page aberta, a grade
// dela, os widgets dentro dela, o catalogo do que da para acrescentar, e as
// funcoes que sao o unico caminho para mudar qualquer coisa.
//
// Cru de proposito: isto e andaime da Settings. A passada estetica dos
// styles e de um passo bem mais tarde, depois que a estrutura fechar.
Rectangle {
    id: root

    required property var pageNames
    required property string selectedPage
    required property var selectedGrid
    required property var widgets
    required property var catalog
    required property var stylesOf
    required property var styleOfWidget
    required property var selectPage
    required property var createPage
    required property var deletePage
    required property var nudgeGrid
    required property var addWidget
    required property var removeWidget
    required property var nudgeCell
    required property var setStyle

    color: "#262626"
    border.color: "#3a3a3a"
    border.width: 1
    radius: 4

    component Chip: Rectangle {
        id: chip
        property string label
        property bool active
        signal activated

        width: label.length * 7 + 20
        height: 22
        radius: 11
        color: active ? "#3a6ea5" : "#3a3a3a"

        Text {
            anchors.centerIn: parent
            text: chip.label
            color: "white"
            font.pixelSize: 12
        }

        MouseArea {
            anchors.fill: parent
            onClicked: chip.activated()
        }
    }

    // Um par de setas em volta de um numero. O mesmo gesto que o
    // island-editor usa para offset e tamanho: a celula e inteira, entao
    // nao ha o que digitar, so somar e subtrair.
    component Stepper: Row {
        id: stepper
        property string label
        property int value
        signal stepped(int delta)

        spacing: 4

        Text {
            text: stepper.label
            color: "#999999"
            font.pixelSize: 11
            anchors.verticalCenter: parent.verticalCenter
        }
        Chip { label: "-"; onActivated: stepper.stepped(-1) }
        Text {
            text: String(stepper.value)
            color: "white"
            font.pixelSize: 12
            width: 20
            horizontalAlignment: Text.AlignHCenter
            anchors.verticalCenter: parent.verticalCenter
        }
        Chip { label: "+"; onActivated: stepper.stepped(1) }
    }

    Column {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        // --- as pages que existem -------------------------------------
        Row {
            spacing: 6
            Text {
                text: "Pages:"
                color: "#cccccc"
                font.pixelSize: 12
                anchors.verticalCenter: parent.verticalCenter
            }
            Repeater {
                model: root.pageNames
                delegate: Chip {
                    required property string modelData
                    label: modelData
                    active: modelData === root.selectedPage
                    onActivated: root.selectPage(modelData)
                }
            }
        }

        Row {
            spacing: 6

            Rectangle {
                width: 130
                height: 24
                color: "#1b1b1b"
                border.color: newName.activeFocus ? "#3a6ea5" : "#3a3a3a"
                border.width: 1
                radius: 3

                TextInput {
                    id: newName
                    anchors.fill: parent
                    anchors.margins: 6
                    verticalAlignment: TextInput.AlignVCenter
                    color: "white"
                    font.pixelSize: 12
                    clip: true
                    selectByMouse: true
                    onAccepted: { root.createPage(text); text = ""; }
                }

                Text {
                    anchors.fill: newName
                    visible: newName.text.length === 0 && !newName.activeFocus
                    text: "new page name"
                    color: "#777777"
                    font.pixelSize: 12
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Chip {
                label: "+ create"
                anchors.verticalCenter: parent.verticalCenter
                onActivated: { root.createPage(newName.text); newName.text = ""; }
            }

            // Apagar uma page em uso NAO e acidente: as islands que a
            // vestiam caem no estado empty (decisao 14.3), de proposito e
            // visivelmente, em vez de a shell fingir que nada aconteceu.
            Chip {
                label: "delete page"
                visible: root.selectedPage !== ""
                anchors.verticalCenter: parent.verticalCenter
                onActivated: root.deletePage(root.selectedPage)
            }
        }

        // --- a grade da page aberta -----------------------------------
        Row {
            spacing: 14
            visible: root.selectedPage !== ""

            Text {
                text: "grid of " + root.selectedPage + ":"
                color: "#cccccc"
                font.pixelSize: 12
                anchors.verticalCenter: parent.verticalCenter
            }
            Stepper {
                label: "cols"
                value: root.selectedGrid.cols ?? 10
                onStepped: (delta) => root.nudgeGrid("cols", delta)
            }
            Stepper {
                label: "rows"
                value: root.selectedGrid.rows ?? 4
                onStepped: (delta) => root.nudgeGrid("rows", delta)
            }
        }

        // --- o que da para acrescentar --------------------------------
        Row {
            spacing: 6
            visible: root.selectedPage !== ""

            Text {
                text: "add widget:"
                color: "#999999"
                font.pixelSize: 11
                anchors.verticalCenter: parent.verticalCenter
            }
            Repeater {
                model: root.catalog
                delegate: Chip {
                    required property var modelData
                    label: "+ " + modelData.title
                    onActivated: root.addWidget(modelData.type)
                }
            }
        }

        // --- os widgets dentro dela -----------------------------------
        Text {
            visible: root.selectedPage !== "" && root.widgets.length === 0
            text: "no widgets in this page yet"
            color: "#777777"
            font.pixelSize: 11
        }

        Repeater {
            model: root.widgets

            // Apertado de proposito: quatro steppers mais o nome e o botao
            // nao cabem nos 540 px uteis do painel com o espacamento largo
            // do resto da tela — foi o que a camada 4 pegou.
            delegate: Column {
                id: widgetRow
                required property var modelData
                required property int index

                spacing: 3

                Row {
                spacing: 4

                Text {
                    text: widgetRow.modelData.type
                    color: "white"
                    font.pixelSize: 12
                    width: 90
                    elide: Text.ElideRight
                    anchors.verticalCenter: parent.verticalCenter
                }
                Stepper {
                    label: "x"
                    value: widgetRow.modelData.cell.x ?? 0
                    onStepped: (delta) => root.nudgeCell(widgetRow.index, "x", delta)
                }
                Stepper {
                    label: "y"
                    value: widgetRow.modelData.cell.y ?? 0
                    onStepped: (delta) => root.nudgeCell(widgetRow.index, "y", delta)
                }
                Stepper {
                    label: "w"
                    value: widgetRow.modelData.cell.w ?? 1
                    onStepped: (delta) => root.nudgeCell(widgetRow.index, "w", delta)
                }
                Stepper {
                    label: "h"
                    value: widgetRow.modelData.cell.h ?? 1
                    onStepped: (delta) => root.nudgeCell(widgetRow.index, "h", delta)
                }
                Chip {
                    label: "remove"
                    anchors.verticalCenter: parent.verticalCenter
                    onActivated: root.removeWidget(widgetRow.index)
                }
                }

                // O style numa linha propria, e nao ao lado das celulas:
                // quatro steppers mais o nome ja ocupam a largura util do
                // painel, e foi assim que a linha vazou para fora na 0.508.
                // Os nomes vem do registro, nunca escritos aqui (3.5).
                Row {
                    spacing: 6
                    leftPadding: 90

                    Text {
                        text: "style:"
                        color: "#777777"
                        font.pixelSize: 11
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Repeater {
                        model: root.stylesOf(widgetRow.modelData.type)
                        delegate: Chip {
                            required property var modelData
                            label: modelData.title
                            active: modelData.style === root.styleOfWidget(widgetRow.modelData)
                            onActivated: root.setStyle(widgetRow.index, modelData.style)
                        }
                    }
                }
            }
        }
    }
}
