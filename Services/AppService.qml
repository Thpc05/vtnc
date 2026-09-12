pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

// ═══════════════════════════════════════════
//  APP SERVICE — O que está aberto, e ONDE, num lugar só.
//
//  A divisão do projeto: O QUE está aberto é dado e mora aqui;
//  COMO ele aparece é da ilha (morfando). Enquanto os dois viviam
//  juntos, o estado ficava misturado com a animação.
//
//  MULTI-MONITOR: app e dashboard abrem SÓ no monitor focado — senão
//  toda ilha morfa junto e as barras se copiam. Guardamos o nome do
//  monitor no instante da abertura (`monitor`); cada ilha só reage se
//  for a dela (`showsOn`). O relógio, a wide e os reveals seguem
//  per-monitor de graça (cada barra tem os seus). Volume/brilho não:
//  são do sistema, aparecem em todas as telas.
// ═══════════════════════════════════════════
Singleton {
    id: root

    // Nome da face de app aberta ("none" = nenhuma).
    // A dashboard é uma face como as outras — antes ela era um bool à
    // parte aqui, porque vivia dentro da barra em vez de ser um rosto
    // da ilha. Virou app, e o caso especial sumiu junto
    property string active: "none"

    // Monitor onde o app/dashboard nasceu (nome da screen do Hyprland).
    // "" = nenhum alvo → cai pro comportamento antigo (todas as telas),
    // o que também cobre o caso de o foco não estar disponível.
    property string monitor: ""
    function _focused() {
        return Hyprland.focusedMonitor?.name ?? ""
    }
    // Esta ilha (pela screen) deve mostrar o que está aberto?
    function showsOn(screenName) {
        return monitor === "" || monitor === screenName
    }

    // A coisa aberta pediu pra SOLTAR o input sem fechar — ex: Tools
    // durante o slurp, que precisa da tela livre. Quem hospeda liga
    // isto na face ativa.
    property bool releaseInput: false
    readonly property bool hasApp: active !== "none"
    // Pro shell: mask fullscreen (clique-fora-fecha) e teclado
    readonly property bool grabsInput: hasApp && !releaseInput
    readonly property bool wantsKeyboard: grabsInput
    // Alguma coisa aberta cobrindo a tela?
    readonly property bool isOpen: grabsInput

    function open(name) {
        monitor = _focused()
        active = name
    }

    function toggle(name) {
        if (active === name)
            close()
        else
            open(name)
    }

    function close() {
        active = "none"
        monitor = ""
    }
}
