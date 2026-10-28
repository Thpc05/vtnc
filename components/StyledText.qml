import QtQuick
import qs.theme

Text {
    color: Colors.overBackground
    font.family: Tokens.font.family
    font.pixelSize: Tokens.font.normal
    // caelestia's rounded terminals (Google Sans Flex's ROND axis; other fonts ignore it)
    font.variableAxes: ({ "ROND": 25 })
    verticalAlignment: Text.AlignVCenter
    renderType: Tokens.font.renderType
}
