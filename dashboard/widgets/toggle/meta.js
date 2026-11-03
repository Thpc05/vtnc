.pragma library

// The toggle Dwidgets (Widget.qml): Wi-Fi, Bluetooth, Mixer, the colour scheme, the power profile and
// the wallpaper, each its own Dwidget (the other Qwidgets only go in Quick configs). The toggle is
// 2x1 lying, 1x1 the icon, 1x2 standing, 2x2 / 3x2 a card; its panel is reached only by expanding, at
// a fixed size the user doesn't pick (Wi-Fi / Bluetooth 4x6; the mixer a wide 6x5, bigger since
// 2026-10-17 (user), the devices at the left and the apps at the right).
// 1x1 … 2x2 the compact toggle; 3x3 and up the panel is the face (2026-10-27, user).
// (2026-10-27, user: every toggle has a panel) the colour scheme and the wallpaper act on a click (the
// next scheme, the Wallpaper app), the power profile cycles.

var SIZES = ["2x1", "1x1", "3x1", "1x2", "2x2", "3x3", "4x3", "3x4", "4x4", "5x4", "4x5", "4x6", "5x5", "6x4", "6x5", "6x6", "6x7"];

// the Quick configs looks (2026-10-11): shapes, two tones, tone, each also on the card
function toggle(title, icon, expandSize, trigger) {
    return {
        title: title,
        icon: icon,
        styles: [
            { id: "shapes", title: "Shapes", sizes: SIZES },
            { id: "tones", title: "Two tones", sizes: SIZES },
            { id: "tone", title: "Tone", sizes: SIZES }
        ],
        cards: ["shapes", "tones", "tone"],
        defaults: { idle: { style: "shapes", size: "2x1" }, options: {} },
        expand: { size: expandSize, trigger: trigger || "doubleclick" }
    };
}

// one folder, several Dwidgets: the index lists each id and loads this folder's Widget.qml for it
var metas = {
    wifi: toggle("Wi-Fi", "wifiHigh", "4x6"),
    bluetooth: toggle("Bluetooth", "bluetooth", "4x6"),
    // the Mixer's click opens its panel (it doesn't mute)
    mixer: toggle("Mixer", "faders", "6x7", "click"),
    colorScheme: toggle("Color scheme", "palette", "4x6"),
    powerProfile: toggle("Power profile", "gauge", "4x5"),
    wallpaper: toggle("Wallpaper", "image", "5x6")
};
