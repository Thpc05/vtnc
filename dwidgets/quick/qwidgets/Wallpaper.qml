import QtQuick
import qs.core
import qs.services
import qs.theme
import ".."
import "../panels"

// The wallpaper (2026-10-17, user): a click opens the Wallpaper app, a right click puts a random one from
// the folder (Wallpapers.applyRandom, never the current one; the colours regenerate). An action: no
// on / off; its state is the current wallpaper's name.
Qwidget {
    title: "Wallpaper"
    symbol: "wallpaper"
    icon: Icons.image
    status: Wallpapers.current !== "" ? Wallpapers.name(Wallpapers.current) : "None"
    alternate: () => Wallpapers.applyRandom()
    switchable: false
    panel: Component {
        WallpaperPanel {}
    }

    function toggle() {
        Launch.run("vtnc:wallpaper");
    }
}
