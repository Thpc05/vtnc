.pragma library

// The Helper's Mouse tab (2026-10-17): the clicks that aren't obvious, by place. `button`: Left / Right /
// Middle / Scroll. Checked against the code on 2026-10-17 (RightButton / MiddleButton / onWheel).
var SECTIONS = [
    {
        title: "Island",
        rows: [
            { button: "Left", place: "Bell", text: "Open Notifications" },
            { button: "Right", place: "Bell", text: "Do not disturb on / off" },
            { button: "Scroll", place: "Volume", text: "Volume up / down" },
            { button: "Scroll", place: "Workspaces", text: "Next / previous workspace" },
            { button: "Right", place: "Quick configs", text: "The Qwidget's second action (e.g. a random wallpaper)" },
            { button: "Right", place: "Media", text: "Pick the player" },
            { button: "Scroll", place: "Media", text: "Next / previous track" },
            { button: "Right", place: "Dock", text: "The app's menu" },
            { button: "Middle", place: "Dock", text: "Open a new window" },
            { button: "Right", place: "Tray", text: "The app's menu" },
            { button: "Middle", place: "Tray", text: "The app's second action" },
            { button: "Scroll", place: "Notification", text: "Go through the notifications" },
            { button: "Middle", place: "Notification", text: "Dismiss it" }
        ]
    },
    {
        title: "Dashboard",
        rows: [
            { button: "Left", place: "Wi-Fi / Bluetooth", text: "The icon turns it on / off, the rest opens its panel" },
            { button: "Right", place: "Qwidgets", text: "Open its panel, or its second action" },
            { button: "Right", place: "Wallpaper Qwidget", text: "A random wallpaper (left: the Wallpaper app)" },
            { button: "Right", place: "Media", text: "Pick the player" },
            { button: "Scroll", place: "Media", text: "Next / previous track" },
            { button: "Scroll", place: "Calendar", text: "Previous / next month" },
            { button: "Middle", place: "Calendar", text: "Back to today" }
        ]
    },
    {
        title: "Settings",
        rows: [
            { button: "Right", place: "Layout preview", text: "Turn a Dwidget off" }
        ]
    }
];
