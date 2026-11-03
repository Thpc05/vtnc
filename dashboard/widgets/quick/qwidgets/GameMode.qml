import QtQuick
import qs.base.services
import qs.base.theme
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
