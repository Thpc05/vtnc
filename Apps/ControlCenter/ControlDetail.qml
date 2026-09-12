import QtQuick
import "../../ConfigValues"
import "../../Ui"

// ═══════════════════════════════════════════
//  DASH DETAIL — Contrato de uma tela de detalhe do Control Center.
//
//  O card mostra o ESTADO e alterna; o detalhe mostra a LISTA e
//  escolhe. É a divisão do próprio Control Center do iOS, e é o que
//  permite o card ter tamanho fixo: o que não cabe não fica espremido,
//  vai pro detalhe.
//
//  A ControlCenter não conhece nenhum detalhe concreto — só este contrato,
//  mesmo padrão de Island ↔ IslandFace. Registrar um = criar em
//  Details/ + 1 linha na lista da ControlCenter + `detail:` no card.
//
//  A altura é do CONTEÚDO (implicitHeight): a ilha morfa pra caber, em
//  vez de a lista rolar dentro de uma caixa fixa.
// ═══════════════════════════════════════════
Item {
    id: detail

    // Casa com o `detail:` declarado no card
    property string name: ""
    property string title: ""
    // Ação opcional no canto direito do cabeçalho (rescan, abrir app)
    property string actionIcon: ""

    signal back()
    signal action()

    default property alias content: host.data

    implicitHeight: cabecalho.height + 8 + host.implicitHeight

    // ── CABEÇALHO: voltar · título · ação ──
    Item {
        id: cabecalho

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 30

        Hoverable {
            id: btVoltar

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 28
            height: 24
            onTapped: detail.back()

            Text {
                anchors.centerIn: parent
                text: "󰅁"
                color: btVoltar.hovered ? Theme.textPrimary : Theme.textSecondary
                font { family: Theme.fontIcon; pixelSize: 13 }
                Behavior on color { ColorAnimation { duration: Motion.instant } }
            }
        }

        Text {
            anchors.left: btVoltar.right
            anchors.leftMargin: 6
            anchors.right: btAcao.left
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            text: detail.title
            elide: Text.ElideRight
            color: Theme.textPrimary
            font { family: Theme.fontDisplay; pixelSize: 14; weight: 600 }
        }

        Hoverable {
            id: btAcao

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 28
            height: 24
            visible: detail.actionIcon !== ""
            onTapped: detail.action()

            Text {
                anchors.centerIn: parent
                text: detail.actionIcon
                color: btAcao.hovered ? Theme.textPrimary : Theme.textSecondary
                font { family: Theme.fontIcon; pixelSize: 12 }
                Behavior on color { ColorAnimation { duration: Motion.instant } }
            }
        }
    }

    // Conteúdo do detalhe concreto. Column: as seções empilham
    Column {
        id: host

        anchors.top: cabecalho.bottom
        anchors.topMargin: 8
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 10
    }
}
