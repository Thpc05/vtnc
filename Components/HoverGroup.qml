import QtQuick

// ═══════════════════════════════════════════
//  HOVER GROUP — "um por vez, com paciência".
//
//  Esta lógica estava escrita TRÊS vezes (reveals da barra, widgets da
//  dashboard, faixa que revela a ilha escondida), cada cópia com um
//  grace period ligeiramente diferente. Aqui é uma só.
//
//  O CONTRATO: quem usa alimenta `candidate` (o que o mouse mira
//  AGORA, cru) e lê `shown` (o que deve estar aberto). Entre os dois
//  moram duas esperas:
//
//   · openDelay  — mirar não abre na hora. É o que separa "passei o
//     mouse por cima" de "quero ver isto", e é o que torna uma shell
//     cheia de hover-reveals habitável. Só vale pro PRIMEIRO a abrir:
//     com um já aberto, andar pelos vizinhos troca na hora (senão
//     percorrer o cluster vira uma sequência de esperas).
//
//   · closeGrace — sair não fecha na hora, pro mouse conseguir
//     cruzar do anchor até o painel sem o painel sumir no meio do
//     caminho.
//
//  E o atalho: `openNow()` pula a espera. É o que o clique chama —
//  quem já sabe o que quer não deveria ter que esperar. Serve também
//  pro que se abre sozinho (notificação chegando), que é explícito e
//  nunca deve esperar.
//
//  `closeNow()` é o oposto: fecha sem grace, pra quando não há
//  travessia possível (o mouse saiu da região inteira).
// ═══════════════════════════════════════════
QtObject {
    id: group

    // ── ENTRADA: quem o mouse mira agora (Item, true, ou null) ──
    property var candidate: null

    // ── SAÍDA: quem deve estar aberto ──
    readonly property var shown: _shown
    readonly property bool open: !!_shown

    // Espera antes de abrir. 0 = abre na hora (feedback puro, sem
    // intenção envolvida)
    property int openDelay: Motion.hoverDelay
    // Folga pro mouse cruzar até o conteúdo revelado (e pra perdoar
    // a saída acidental pela borda)
    property int closeGrace: Motion.hoverGrace

    // Estado interno — leia `shown`
    property var _shown: null

    // Mostra JÁ, sem esperar. `c` opcional: sem ele, mostra o candidato
    // atual.
    //
    // ARMADILHA (custou um bug real): esta função NUNCA pode escrever
    // em `candidate`. Quem usa liga `candidate` a um binding
    // (`candidate: root.hoveredReveal`), e atribuir a uma propriedade
    // com binding DESTRÓI o binding — o grupo congelava no valor
    // atribuído e nunca mais via o hover. Escrevemos só em `_shown`.
    function openNow(c) {
        _openTimer.stop()
        _closeTimer.stop()
        group._shown = (c !== undefined) ? c : group.candidate
    }

    // Fecha JÁ, sem grace — pra quando não há travessia possível
    function closeNow() {
        _openTimer.stop()
        _closeTimer.stop()
        group._shown = null
    }

    onCandidateChanged: {
        if (candidate) {
            _closeTimer.stop()
            if (_shown) {
                // Já tem alguém aberto: trocar de vizinho é imediato.
                // A espera é o preço de ENTRAR no grupo, não de andar
                // dentro dele
                _shown = candidate
            } else if (openDelay > 0) {
                _openTimer.restart()
            } else {
                _shown = candidate
            }
        } else {
            _openTimer.stop()
            if (_shown)
                _closeTimer.restart()
        }
    }

    property Timer _openTimer: Timer {
        interval: group.openDelay
        onTriggered: group._shown = group.candidate
    }

    property Timer _closeTimer: Timer {
        interval: group.closeGrace
        onTriggered: group._shown = null
    }
}
