import ".."
import "."
import QtQuick
import QtQuick.Effects
import "../../Services"

// ═══════════════════════════════════════════
//  PILL — A Ilha Dinâmica.
//  Container genérico: NÃO conhece nenhum módulo concreto. As faces
//  (PillFace) são plugadas via `faces` pelo shell.qml e podem ser
//  adicionadas/removidas sem tocar neste arquivo.
//
//  Coreografia do morph (ENTRE faces):
//    1. conteúdo atual some          (faceFadeOut)
//    2. face troca → pill morfa      (morphDuration)
//    3. conteúdo novo entra          (faceFadeInDelay + faceFadeIn)
//
//  DENTRO da mesma face a pill segue o contentWidth/Height cru — é a
//  face que anima o próprio tamanho. Assim conteúdo e borda derivam
//  do mesmo valor e nunca dessincronizam.
// ═══════════════════════════════════════════
Item {
    id: root

    width: pill.width
    height: pill.height

    // Faces plugadas pelo shell.qml (único ponto de registro)
    property list<Item> faces

    // Este monitor é o dono do que está aberto? (setado pelo shell)
    // App e dashboard só nascem na ilha do monitor focado; as outras
    // ficam na barra, sem morfar. A barra idle/wide/reveals não passa
    // por aqui — é per-monitor de graça
    property bool monitorActive: true

    // ═══════════════════════════════════════════
    //  ESTADO — quem manda é o AppService
    //  (o que abrir é dado; COMO abrir é da ilha: morfando)
    // ═══════════════════════════════════════════
    readonly property string appState: monitorActive ? AppService.active : "none"
    readonly property bool dashForced: monitorActive && AppService.dashboard

    // Prioridade: app > bar (a bar cuida de idle/hover sozinha).
    // OSD não entra: é conteúdo do Center, não rosto da ilha
    readonly property string desiredState:
        appState !== "none" ? appState : "bar"

    // shownState segue desiredState com a coreografia do morph
    property string shownState: "bar"
    property Item activeFace: null

    readonly property bool morphing: morphSeq.running

    // Devolve pro service o que só a face sabe (ela é nossa)
    Binding {
        target: AppService
        property: "releaseInput"
        value: !!(root.activeFace && root.activeFace.releaseInput)
        when: root.activeFace !== null
    }
    Binding {
        target: AppService
        property: "dashKeyboard"
        value: !!(root.activeFace && root.activeFace.dashKeyboard)
        when: root.activeFace !== null
    }

    // ═══════════════════════════════════════════
    //  API
    // ═══════════════════════════════════════════
    function faceByName(n) {
        for (let i = 0; i < faces.length; i++)
            if (faces[i].name === n)
                return faces[i]
        return null
    }

    function toggleApp(name) {
        const f = faceByName(name)
        if (!f || f.role !== "app")
            return
        AppService.toggle(name)
    }

    // Wide é um MODO, não um estado: só inverte o persistido, e a
    // bar reflete quando estiver visível
    function toggleWide() {
        Persist.state.wideBar = !Persist.state.wideBar
    }

    // ═══════════════════════════════════════════
    //  PLUG DAS FACES — wiring automático pelo contrato.
    //  Duck-typing de propósito: a face que não tem o membro
    //  simplesmente não recebe aquele fio.
    // ═══════════════════════════════════════════
    Component.onCompleted: {
        for (let i = 0; i < faces.length; i++) {
            const f = faces[i]
            f.parent = faceHost
            f.anchors.fill = faceHost
            // Face pede pra aparecer (só apps fazem isso)
            if (f.requested !== undefined)
                f.requested.connect(() => root.toggleApp(f.name))
            if (f.closeRequested !== undefined)
                f.closeRequested.connect(() => AppService.close())
            // Clique no fundo da linha de topo da bar alterna a dashboard
            if (f.backgroundTapped !== undefined)
                f.backgroundTapped.connect(() => AppService.toggleDashboard())
            // A face padrão (bar) recebe o forçar-dashboard do IPC
            if (f.forceExpand !== undefined)
                f.forceExpand = Qt.binding(() => root.dashForced)
        }
        syncFaces()
    }

    onShownStateChanged: syncFaces()
    function syncFaces() {
        activeFace = faceByName(shownState)
        for (let i = 0; i < faces.length; i++) {
            faces[i].active = (faces[i] === activeFace)
            faces[i].visible = (faces[i] === activeFace)
        }
    }

    // ═══════════════════════════════════════════
    //  COREOGRAFIA DO MORPH
    // ═══════════════════════════════════════════
    onDesiredStateChanged: if (desiredState !== shownState) morphSeq.restart()

    SequentialAnimation {
        id: morphSeq

        // 1. conteúdo atual some
        NumberAnimation {
            target: faceHost
            property: "opacity"
            to: 0
            duration: Pill_Theme.faceFadeOut
            easing.type: Easing.InQuad
        }
        // 2. troca a face → Behaviors da pill morfam o tamanho
        ScriptAction { script: root.shownState = root.desiredState }
        // 3. espera a borda chegar perto do destino
        PauseAnimation { duration: Pill_Theme.faceFadeInDelay }
        // 4. conteúdo novo entra
        NumberAnimation {
            target: faceHost
            property: "opacity"
            to: 1
            duration: Pill_Theme.faceFadeIn
            easing.type: Easing.OutQuad
        }
    }

    // (o IPC mora no shell.qml: um handler por target na shell
    //  inteira. Aqui dentro ele duplicaria por tela, e só o primeiro
    //  registrado atenderia)

    // ═══════════════════════════════════════════
    //  SOMBRA — 360° ao redor da pill
    // ═══════════════════════════════════════════
    MultiEffect {
        source: pill
        anchors.fill: pill
        shadowEnabled: true
        shadowColor: Theme.shadow
        shadowBlur: 1.0
        shadowVerticalOffset: 0
        shadowHorizontalOffset: 0
        z: -1
    }

    // ═══════════════════════════════════════════
    //  A PILL — retângulo morfante
    // ═══════════════════════════════════════════
    Rectangle {
        id: pill

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        clip: true // nada renderiza fora da pill, nem por 1 frame
        color: Theme.bg

        width: root.activeFace ? root.activeFace.contentWidth : Pill_Theme.width
        height: root.activeFace ? root.activeFace.contentHeight : Pill_Theme.height
        // Radius deriva da height JÁ animada, sem Behavior próprio: um
        // Behavior aqui perseguiria um alvo móvel e ficaria pra trás,
        // deixando a pill quadrada no meio do morph
        radius: Pill_Theme.radius
        // Behaviors SÓ durante a troca de face — dentro de uma face a
        // pill segue cru o tamanho que a própria face anima
        Behavior on width {
            enabled: root.morphing
            Anim { duration: Pill_Theme.morphDuration }
        }
        Behavior on height {
            enabled: root.morphing
            Anim { duration: Pill_Theme.morphDuration }
        }

        // Segura o clique pra ele não atravessar a pill (o toggle da
        // dashboard vive no fundo da linha de topo da Bar)
        TapHandler {}

        // Host das faces (a coreografia anima a opacity daqui)
        Item {
            id: faceHost
            anchors.fill: parent
        }
    }
}
