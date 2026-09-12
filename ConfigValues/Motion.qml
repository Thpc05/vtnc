pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "."

// ═══════════════════════════════════════════
//  MOTION — A escala de movimento da shell. UM lugar.
//
//  Antes existiam 6 durações soltas no Theme e 2 curvas concorrentes.
//  Seis números não são um estilo: são sedimento. Aqui são quatro
//  durações com PAPEL, e uma curva só para cada tipo de mudança.
//
//  A REGRA — escolha pelo que está mudando, não pelo tempo:
//   · muda FORMA (largura, altura, um driver 0→1 que vira tamanho)
//       → Settle   — passa do alvo e volta. É a assinatura da ilha.
//   · muda POSIÇÃO ou OPACIDADE (x/y, fade, slide)
//       → Smooth   — chega e para. Overshoot em posição vira wobble,
//                    e em opacidade não existe (o Qt clampa).
//   · tracking contínuo (slider com o botão preso)
//       → nem um nem outro: OutCubic curto com `track`. Retargetar
//         uma curva com overshoot a cada evento vira tremedeira.
//
//  ─────────────────────────────────────────
//  PERSISTÊNCIA (o mesmo padrão em Theme, Config e IslandTheme):
//   · os valores moram no JsonAdapter abaixo, com o DEFAULT junto;
//   · a shell LÊ pelas readonly properties (Motion.standard);
//   · quem ESCREVE (o config app) usa Motion.data.standard = x;
//   · o que é DERIVADO de outro token não entra no adapter — fica
//     como binding aqui, senão daria pra salvar um estado incoerente.
//
//  ARMADILHAS do FileView/JsonAdapter (todas custaram bug real):
//   · NUNCA `property alias` para dentro do adapter — o alias
//     re-inicializa os defaults POR CIMA dos valores carregados.
//     Binding (`: d.campo`) pode; alias não;
//   · auto-save só DEPOIS do load, senão a carga sobrescreve o
//     arquivo com defaults — daí o gate `loaded` + o coalesce;
//   · path SEMPRE absoluto (ver Config/Paths.qml);
//   · Singleton é LAZY e o load aplica DEPOIS do primeiro acesso:
//     bindings se corrigem sozinhos, mas leitura IMPERATIVA em
//     Component.onCompleted pega defaults.
//
//  A reescrita logo após o load é DE PROPÓSITO: um arquivo antigo
//  sem as chaves novas ganha os defaults delas em disco, então o
//  arquivo se migra sozinho quando um token é adicionado aqui.
//
//  Adicionar um token = 1 property no adapter + 1 readonly aqui.
// ═══════════════════════════════════════════
Singleton {
    id: root

    // Escrita (config app). Leitura normal usa as properties abaixo
    readonly property var data: d
    property bool loaded: false

    // ════════════════════════════════════════
    //  DURAÇÕES (ms)
    // ════════════════════════════════════════
    // Feedback de mira: cor de hover, acender de borda, cadeado
    readonly property int instant: d.instant
    // Fades de conteúdo: painel de reveal, listas, troca de item
    readonly property int quick: d.quick
    // Expansões: pill wide, reveal abrindo, widget crescendo
    readonly property int standard: d.standard
    // Tracking de slider (volume/brilho com o botão segurado)
    readonly property int track: d.track

    // ════════════════════════════════════════
    //  ASSENTAMENTO
    //  Parâmetro do OutBack — NÃO é a fração que passa do alvo.
    //  A relação é (4/27)·s³/(s+1)², bem não-linear:
    //    0   → 0.0%  · para seco (OutCubic exato)
    //    0.4 → 0.5%  · subliminar, não vale o custo
    //    0.7 → 1.8%  · discreto demais nesta escala
    //    1.0 → 3.7%  · o padrão daqui (a faixa da Apple)
    //    1.2 → 5.3%  · notável
    //    1.7 → 10.0% · o default do Qt, cartunesco aqui
    //
    //  ATENÇÃO: vale nos DOIS sentidos e sobre o DELTA. Fechar a
    //  control center (altura 430 → 32) mergulha abaixo de 32 antes de
    //  voltar — é a squash que dá peso, mas o piso cai rápido:
    //    1.0 → até ~17px · 1.2 → até ~11px · 1.5 → encosta em 0
    //  Acima de ~1.3 a ilha pinça visivelmente ao fechar.
    // ════════════════════════════════════════
    readonly property real overshoot: d.overshoot

    // ════════════════════════════════════════
    //  PACIÊNCIA DO HOVER (ms)
    //  Quanto o mouse precisa DESCANSAR sobre uma coisa antes dela se
    //  abrir, e quanto ela sobrevive depois que ele sai.
    //  Curto demais (<200) não filtra nada; longo demais (>500)
    //  parece que a shell travou. Quem não quer esperar clica.
    // ════════════════════════════════════════
    readonly property int hoverDelay: d.hoverDelay
    readonly property int hoverGrace: d.hoverGrace

    // ── persistência ──
    function saveSoon() {
        if (loaded)
            saveTimer.restart()
    }

    // Coalesce: várias mudanças no mesmo tick = uma escrita só
    Timer {
        id: saveTimer
        interval: 100
        onTriggered: file.writeAdapter()
    }

    FileView {
        id: file

        path: Paths.motion
        // Tem que estar pronto antes dos consumidores montarem, senão
        // a shell nasce com os defaults e pisca pro valor salvo
        blockLoading: true

        onLoaded: root.loaded = true
        onLoadFailed: {
            root.loaded = true
            writeAdapter() // ainda não existe: cria com os defaults
        }
        // UM handler cobre TODAS as properties do adapter — não
        // precisa de um onXChanged por token
        onAdapterUpdated: root.saveSoon()

        adapter: JsonAdapter {
            id: d

            property int instant: Defaults.motion.instant
            property int quick: Defaults.motion.quick
            property int standard: Defaults.motion.standard
            property int track: Defaults.motion.track
            property real overshoot: Defaults.motion.overshoot
            property int hoverDelay: Defaults.motion.hoverDelay
            property int hoverGrace: Defaults.motion.hoverGrace
        }
    }
}
