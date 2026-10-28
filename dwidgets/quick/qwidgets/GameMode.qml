import QtQuick
import qs.services
import qs.theme
import ".."

Qwidget {
    title: "Game mode"
    symbol: "sports_esports"
    icon: Icons.gameMode
    active: GameModeClient.toggled

    function toggle() {
        GameModeClient.toggle();
    }
}
