import QtQuick
import "Cards"
import "Details"
import "../../ConfigValues"
import "../../Island"
import "../../Ui"

// ═══════════════════════════════════════════
//  CONTROL CENTER — a face que a ilha vira.
//
//  O QUE SUMIU, e por quê: a versão anterior tinha grid por
//  coordenada, solver de colisão, empurrão-em-sombra, drag pra
//  reposicionar e pin persistido — ~250 linhas. Tudo aquilo existia
//  porque as peças mudavam de tamanho sozinhas (hover expandia) e
//  precisavam se desviar. Com tamanho FIXO não há o que desviar, e o
//  layout vira o que ele sempre quis ser: uma coluna de linhas.
//
//  Mexer no layout = mexer nestas linhas. Não é configurável em
//  runtime de propósito — posição de card é desenho, não preferência.
//
//  Registrar um card = criar em Cards/ + colocar aqui.
//
//  É uma FACE DE APP, não um pedaço da barra. Antes ela crescia pra
//  baixo dentro da Bar, o que deixava o relógio, os workspaces e o
//  cluster de reveals pendurados em cima dela. Um Control Center não
//  é continuação da barra: a ilha MORFA nele, como faz no launcher.
// ═══════════════════════════════════════════
IslandFace {
    id: root

    name: "controlcenter"
    role: "app"
    // Virou app de verdade, então Esc fecha — como no launcher
    grabsKeyboard: true

    // ═══════════════════════════════════════════
    //  DETALHE — o card mostra o ESTADO e alterna; o detalhe mostra a
    //  LISTA e escolhe. É essa divisão que deixa o card ter tamanho
    //  fixo: o que não cabe não fica espremido, vai pro detalhe.
    //
    //  A ControlCenter não conhece nenhum detalhe concreto, só o contrato
    //  ControlDetail. Registrar = criar em Details/ + 1 id aqui + o
    //  `detail:` no card.
    // ═══════════════════════════════════════════
    readonly property list<Item> detalhes: [redeDet, btDet, audioDet]
    property string detail: ""

    readonly property Item detalheAtivo: {
        for (let i = 0; i < detalhes.length; i++)
            if (detalhes[i].name === detail)
                return detalhes[i]
        return null
    }

    // Fechar volta pra grade: reabrir a control center num detalhe deixado
    // aberto dias atrás não é o que se espera
    onActiveChanged: if (!active) detail = ""

    // Esc volta UM nível: detalhe → grade → fecha
    Keys.onEscapePressed: {
        if (detail !== "")
            detail = ""
        else
            root.closeRequested()
    }

    Component.onCompleted: {
        for (let i = 0; i < detalhes.length; i++) {
            const d = detalhes[i]
            d.parent = detalheHost
            d.width = Qt.binding(() => detalheHost.width)
            d.visible = Qt.binding(() => root.detalheAtivo === d)
            d.back.connect(() => root.detail = "")
        }
    }

    readonly property real gap: Theme.controlGap
    // Duas colunas de cards, com o vão no meio
    readonly property real meia: (pilha.width - gap) / 2
    // Altura de um card de toggle; o card de mídia vale dois + o vão
    readonly property real unidade: Theme.controlCardHeight

    contentWidth: Theme.controlWidth
    // A ilha morfa pra caber o detalhe, em vez de a lista rolar dentro
    // de uma caixa fixa. Settle porque é mudança de FORMA — e quem
    // anima é a face (contrato do IslandFace: dentro de uma face é ela
    // que anima o próprio tamanho; a Island segue cru)
    contentHeight: (detalheAtivo ? detalheAtivo.implicitHeight
                                 : pilha.implicitHeight)
                   + Theme.contentPadding * 2
    Behavior on contentHeight {
        enabled: root.active
        Settle {}
    }

    // ── HOST DO DETALHE ── (os detalhes são reparentados pra cá)
    Item {
        id: detalheHost

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Theme.contentPadding
        height: root.detalheAtivo ? root.detalheAtivo.implicitHeight : 0
        opacity: root.detalheAtivo ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { Smooth { duration: Motion.quick } }
    }

    NetworkDetail   { id: redeDet }
    BluetoothDetail { id: btDet }
    AudioDetail     { id: audioDet }

    Column {
        id: pilha

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Theme.contentPadding
        spacing: root.gap
        opacity: root.detalheAtivo ? 0 : 1
        visible: opacity > 0
        Behavior on opacity { Smooth { duration: Motion.quick } }

        // ── LINHA 1: Wi-Fi/Bluetooth empilhados | Mídia (altura dupla)
        Row {
            width: parent.width
            spacing: root.gap

            Column {
                width: root.meia
                spacing: root.gap

                WifiCard {
                    width: parent.width
                    height: root.unidade
                    detail: "network"
                    onDetailRequested: nome => root.detail = nome
                }
                BluetoothCard {
                    width: parent.width
                    height: root.unidade
                    detail: "bluetooth"
                    onDetailRequested: nome => root.detail = nome
                }
            }

            MediaCard {
                width: root.meia
                // Acompanha a coluna ao lado: dois cards mais o vão
                height: root.unidade * 2 + root.gap
            }
        }

        // ── LINHA 2 e 3: os sliders, largura cheia ──
        // Mesma altura dos toggles: agora eles têm rótulo EM CIMA do
        // trilho, então precisam das duas faixas. Encolher aqui
        // espremeria o trilho contra o texto
        BrightnessCard {
            width: parent.width
            height: root.unidade
        }

        VolumeCard {
            width: parent.width
            height: root.unidade
            detail: "audio"
            onDetailRequested: nome => root.detail = nome
        }
    }
}
