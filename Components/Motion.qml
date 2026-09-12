pragma Singleton
import QtQuick

// ═══════════════════════════════════════════
//  MOTION — A escala de movimento da shell. UM lugar.
//
//  Antes existiam 6 durações soltas no Theme (expandDuration,
//  dashDuration, fadeDuration, hoverFade, osdTrackDuration,
//  animDuration) e 2 curvas concorrentes. Seis números não são um
//  estilo: são sedimento. Aqui são quatro durações com PAPEL, e uma
//  curva só para cada tipo de mudança.
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
// ═══════════════════════════════════════════
QtObject {
    // ════════════════════════════════════════
    //  DURAÇÕES (ms)
    // ════════════════════════════════════════
    // Feedback de mira: cor de hover, acender de borda, cadeado
    readonly property int instant: 120
    // Fades de conteúdo: painel de reveal, listas, troca de item
    readonly property int quick: 150
    // Expansões: pill wide, reveal abrindo, widget crescendo
    readonly property int standard: 320
    // Tracking de slider (volume/brilho com o botão segurado)
    readonly property int track: 140

    // ════════════════════════════════════════
    //  PACIÊNCIA DO HOVER (ms)
    //  Quanto o mouse precisa DESCANSAR sobre uma coisa antes dela se
    //  abrir. Não é animação: é a diferença entre "passei por cima" e
    //  "quero ver isto". Sem isso, atravessar a barra dispara três
    //  painéis no caminho.
    //  Quem não quer esperar clica — o clique pula a espera (ver
    //  HoverGroup.openNow). Curto demais (<200) não filtra nada;
    //  longo demais (>500) parece que a shell travou.
    // ════════════════════════════════════════
    readonly property int hoverDelay: 350

    // Quanto o que está aberto SOBREVIVE depois do mouse sair. Serve a
    // dois propósitos: deixar o mouse cruzar do anchor até o painel
    // revelado, e perdoar a saída acidental pela borda da ilha.
    // Curto demais e o painel foge do cursor; longo demais e a ilha
    // fica "grudada" aberta depois que você já saiu.
    readonly property int hoverGrace: 450

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
    //  dashboard (altura 430 → 32) mergulha abaixo de 32 antes de
    //  voltar — é a squash que dá peso, mas o piso cai rápido:
    //    1.0 → até ~17px · 1.2 → até ~11px · 1.5 → encosta em 0
    //  Acima de ~1.3 a ilha pinça visivelmente ao fechar.
    // ════════════════════════════════════════
    readonly property real overshoot: 1.0
}
