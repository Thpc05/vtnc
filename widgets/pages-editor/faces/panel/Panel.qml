import QtQuick

// A unica face do vtnc.pages-editor. Tudo o que o module entrega esta
// declarado aqui (decisao 3.5b): a lista de pages, a page aberta, a grade
// dela, os widgets dentro dela, o catalogo do que da para acrescentar, e as
// funcoes que sao o unico caminho para mudar qualquer coisa.
//
// Cru de proposito: isto e andaime da Settings. A passada estetica dos
// faces e de um passo bem mais tarde, depois que a estrutura fechar.
Rectangle {
    id: root

    required property var pageNames
    required property string selectedPage
    required property var selectedGrid
    required property var widgets
    required property var catalog
    required property var facesOf
    required property var faceOfWidget
    required property var selectPage
    required property var createPage
    required property var deletePage
    required property var nudgeGrid
    required property var addWidget
    required property var removeWidget
    required property var nudgeCell
    required property var setFace
    required property var optionSchemaOf
    required property var optionValuesOf
    required property var optionProblemsOf
    required property var setOption
    required property var colorRoles

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

    // Sete papeis de cor em fila nao cabem na largura util do painel: a
    // camada 4 pegou a fila inteira vazando para fora. Chip menor e, ainda
    // assim, dentro de um Flow que quebra a linha — um papel novo na lista
    // da 3.4c nao pode voltar a estourar a borda.
    component RoleChip: Rectangle {
        id: roleChip
        property string label
        property bool active
        signal activated

        width: label.length * 5.5 + 12
        height: 18
        radius: 9
        color: active ? "#3a6ea5" : "#3a3a3a"

        Text {
            anchors.centerIn: parent
            text: roleChip.label
            color: "white"
            font.pixelSize: 9
        }

        MouseArea {
            anchors.fill: parent
            onClicked: roleChip.activated()
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
                    onActivated: root.addWidget(modelData.module)
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
                    text: widgetRow.modelData.module
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

                // A face numa linha propria, e nao ao lado das celulas:
                // quatro steppers mais o nome ja ocupam a largura util do
                // painel, e foi assim que a linha vazou para fora na 0.508.
                // Os nomes vem do registro, nunca escritos aqui (3.5).
                Row {
                    spacing: 6
                    leftPadding: 90

                    Text {
                        text: "face:"
                        color: "#777777"
                        font.pixelSize: 11
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Repeater {
                        model: root.facesOf(widgetRow.modelData.module)
                        delegate: Chip {
                            required property var modelData
                            label: modelData.title
                            active: modelData.face === root.faceOfWidget(widgetRow.modelData)
                            onActivated: root.setFace(widgetRow.index, modelData.face)
                        }
                    }
                }

                // --- as opcoes da face vestido (0.510, decisao 3.4) ----
                //
                // Nada aqui conhece opcao nenhuma pelo nome: o painel
                // desenha o controle que a declaracao pediu, e so os
                // cinco da 3.4b existem. Uma face novo traz as opcoes
                // dele e esta tela nao muda.
                Repeater {
                    model: root.optionSchemaOf(widgetRow.modelData)

                    delegate: Row {
                        id: optionRow
                        required property var modelData

                        readonly property var values: root.optionValuesOf(widgetRow.modelData)
                        readonly property var value: values[modelData.key]

                        spacing: 6
                        leftPadding: 90

                        Text {
                            text: optionRow.modelData.title + ":"
                            color: "#777777"
                            font.pixelSize: 11
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        // toggle
                        Chip {
                            visible: optionRow.modelData.kind === "toggle"
                            label: optionRow.value ? "on" : "off"
                            active: !!optionRow.value
                            onActivated: root.setOption(widgetRow.index, optionRow.modelData.key, !optionRow.value)
                        }

                        // number: o passo vem da declaracao, e o limite e
                        // imposto aqui tambem - o botao nao oferece sair
                        // da faixa que a face pediu.
                        Row {
                            visible: optionRow.modelData.kind === "number"
                            spacing: 4
                            Chip {
                                label: "-"
                                onActivated: root.setOption(widgetRow.index, optionRow.modelData.key,
                                    Math.max(optionRow.modelData.min,
                                             optionRow.value - (optionRow.modelData.step ?? 1)))
                            }
                            Text {
                                text: String(optionRow.value)
                                color: "white"
                                font.pixelSize: 12
                                width: 26
                                horizontalAlignment: Text.AlignHCenter
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Chip {
                                label: "+"
                                onActivated: root.setOption(widgetRow.index, optionRow.modelData.key,
                                    Math.min(optionRow.modelData.max,
                                             optionRow.value + (optionRow.modelData.step ?? 1)))
                            }
                            Text {
                                visible: (optionRow.modelData.unit ?? "plain") !== "plain"
                                text: optionRow.modelData.unit ?? ""
                                color: "#666666"
                                font.pixelSize: 10
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        // choice
                        Row {
                            visible: optionRow.modelData.kind === "choice"
                            spacing: 4
                            Repeater {
                                model: optionRow.modelData.choices ?? []
                                delegate: Chip {
                                    required property var modelData
                                    label: modelData.title
                                    active: modelData.value === optionRow.value
                                    onActivated: root.setOption(widgetRow.index, optionRow.modelData.key, modelData.value)
                                }
                            }
                        }

                        // role: papel do esquema, nunca uma cor digitada
                        // (decisao 3.4b/3.4c).
                        Flow {
                            visible: optionRow.modelData.kind === "role"
                            width: root.width - 200
                            spacing: 3
                            Repeater {
                                model: root.colorRoles
                                delegate: RoleChip {
                                    required property string modelData
                                    label: modelData
                                    active: modelData === optionRow.value
                                    onActivated: root.setOption(widgetRow.index, optionRow.modelData.key, modelData)
                                }
                            }
                        }

                        // text: confirmado so no fim da edicao, nunca a
                        // cada tecla - cada confirmacao e uma escrita.
                        Rectangle {
                            visible: optionRow.modelData.kind === "text"
                            width: 150
                            height: 22
                            color: "#1b1b1b"
                            border.color: optionField.activeFocus ? "#3a6ea5" : "#3a3a3a"
                            border.width: 1
                            radius: 3

                            TextInput {
                                id: optionField
                                anchors.fill: parent
                                anchors.margins: 5
                                verticalAlignment: TextInput.AlignVCenter
                                color: "white"
                                font.pixelSize: 11
                                clip: true
                                selectByMouse: true
                                text: optionRow.modelData.kind === "text" ? (optionRow.value ?? "") : ""
                                onEditingFinished: root.setOption(widgetRow.index, optionRow.modelData.key, text)
                            }
                        }
                    }
                }

                // O que a shell RECUSOU do meta da face, dito em voz alta
                // (decisao 3.4d). Nao desenhar e esconder o problema; o
                // autor da face precisa saber que aquela opcao sumiu.
                Repeater {
                    model: root.optionProblemsOf(widgetRow.modelData)

                    delegate: Text {
                        required property var modelData
                        leftPadding: 90
                        text: "⚠ option rejected: " + modelData.error
                        color: "#b06a4a"
                        font.pixelSize: 10
                    }
                }
            }
        }
    }
}
