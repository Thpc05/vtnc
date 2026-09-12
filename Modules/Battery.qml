import QtQuick
import "../Components"
import "../Services"

// ═══════════════════════════════════════════
//  BATTERY — O ícone da bateria por nível.
//  Só desenha: nível, glyph e estimativa são do BatteryService.
// ═══════════════════════════════════════════
Text {
    text: BatteryService.icon
    // Igual aos vizinhos do cluster: só grita (danger) quando é aviso
    // de verdade — nível baixo e sem estar carregando. Carregando ou
    // acima do nível, é só mais um ícone
    color: BatteryService.warning ? Theme.danger : Theme.textSecondary
    font { family: Theme.fontIcon; pixelSize: 13 }
    Behavior on color { ColorAnimation { duration: Motion.instant } }
}
