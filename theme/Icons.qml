pragma Singleton

import QtQuick

// The shell's icons: Material Symbols Rounded names (the M3 icon set; components/Icon and
// kit/MaterialIcon draw them with the M3 axes). The property names are the shell's own (from its
// Phosphor days); brand icons Material lacks are Nerd Font rich text.
QtObject {
    readonly property string font: "Material Symbols Rounded"

    // Navigation and UI
    readonly property string apps: "apps"
    readonly property string squaresFour: "dashboard"
    readonly property string dotsNine: "apps"
    readonly property string gear: "settings"
    readonly property string slidersHorizontal: "tune"
    readonly property string sliders: "tune"
    readonly property string faders: "tune"
    readonly property string stack: "stacks"
    readonly property string pill: "pill"
    // the island settings page: mountains (user's pick until Material Symbols has an island;
    // tried: top_panel_open, pen / eraser sizes turned 45°, crop_16_9, hdr_strong)
    readonly property string island: "landscape"
    readonly property string paintBrush: "brush"
    readonly property string palette: "palette"
    readonly property string transparency: "opacity"
    readonly property string puzzlePiece: "extension"
    readonly property string info: "info"
    readonly property string magnifyingGlass: "search"
    readonly property string caretRight: "chevron_right"
    readonly property string caretLeft: "chevron_left"
    readonly property string caretDown: "expand_more"
    readonly property string caretUp: "expand_less"
    readonly property string plus: "add"
    readonly property string minus: "remove"
    readonly property string check: "check"
    readonly property string copy: "content_copy"
    readonly property string clipboard: "content_paste"
    readonly property string notes: "sticky_note_2"
    readonly property string dino: "sports_esports"
    readonly property string cancel: "close"
    readonly property string x: "close"
    readonly property string eye: "visibility"
    readonly property string eyeSlash: "visibility_off"
    readonly property string arrowCounterClockwise: "undo"
    readonly property string arrowClockwise: "refresh"
    readonly property string arrowLeft: "arrow_back"
    readonly property string folder: "folder"
    readonly property string image: "image"
    readonly property string textT: "text_fields"
    readonly property string eyedropper: "colorize"
    readonly property string selection: "screenshot_region"
    readonly property string calendarBlank: "calendar_month"
    readonly property string visualizer: "graphic_eq"
    readonly property string window: "web_asset"
    readonly property string dock: "dock_to_bottom"
    readonly property string clock: "schedule"
    readonly property string trash: "delete"
    readonly property string globe: "public"
    readonly property string lockSimple: "lock"

    // Session
    readonly property string power: "power_settings_new"
    readonly property string lock: "lock"
    readonly property string suspend: "bedtime"
    readonly property string hibernate: "ac_unit"
    readonly property string logout: "logout"
    readonly property string reboot: "restart_alt"
    readonly property string shutdown: "power_settings_new"

    // Tools and recording
    readonly property string camera: "photo_camera"
    readonly property string screencast: "filter_center_focus"
    readonly property string monitor: "desktop_windows"
    readonly property string monitorPlay: "videocam"
    readonly property string microphone: "mic"
    readonly property string stop: "stop"
    readonly property string record: "radio_button_checked"

    // Media
    readonly property string play: "play_arrow"
    readonly property string pause: "pause"
    readonly property string next: "skip_next"
    readonly property string previous: "skip_previous"
    readonly property string shuffle: "shuffle"
    readonly property string repeat: "repeat"
    readonly property string repeatOnce: "repeat_one"
    readonly property string player: "music_note"

    // Audio
    readonly property string speakerHigh: "volume_up"
    readonly property string speakerLow: "volume_down"
    readonly property string speakerNone: "volume_mute"
    readonly property string speakerX: "volume_off"
    readonly property string mic: "mic"
    readonly property string micSlash: "mic_off"

    // Notifications
    readonly property string bell: "notifications"
    readonly property string bellRinging: "notifications_active"
    readonly property string bellZ: "notifications_paused"
    readonly property string bellSlash: "notifications_off"
    readonly property string alert: "warning"
    readonly property string timer: "timer"

    // System
    readonly property string sun: "light_mode"
    readonly property string moon: "dark_mode"
    readonly property string lightning: "bolt"
    readonly property string plug: "power"
    readonly property string leaf: "eco"
    readonly property string gauge: "balance"
    readonly property string gameMode: "sports_esports"
    readonly property string caffeine: "coffee"
    readonly property string thermometer: "device_thermostat"
    readonly property string nightLight: "nightlight"
    readonly property string batteryFull: "battery_full"
    readonly property string batteryHigh: "battery_6_bar"
    readonly property string batteryMedium: "battery_4_bar"
    readonly property string batteryLow: "battery_2_bar"
    readonly property string batteryEmpty: "battery_0_bar"
    readonly property string batteryCharging: "battery_charging_full"

    // Network
    readonly property string wifiHigh: "wifi"
    readonly property string wifiMedium: "network_wifi_2_bar"
    readonly property string wifiLow: "network_wifi_1_bar"
    readonly property string wifiNone: "signal_wifi_0_bar"
    readonly property string wifiOff: "wifi_off"
    readonly property string bluetooth: "bluetooth"
    readonly property string bluetoothConnected: "bluetooth_connected"
    readonly property string bluetoothOff: "bluetooth_disabled"

    // Brands (Symbols Nerd Font)
    readonly property string spotify: "<font face='Symbols Nerd Font Mono'>󰓇</font>"
    readonly property string firefox: "<font face='Symbols Nerd Font Mono'>󰈹</font>"
    readonly property string chromium: "<font face='Symbols Nerd Font Mono'></font>"
    readonly property string telegram: "<font face='Symbols Nerd Font Mono'></font>"
}
