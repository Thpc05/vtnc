import QtQuick
import qs.core
import qs.services
import qs.components
import qs.theme
import "../../controls"

// The Image Dwidget's options (2026-10-27, user): the file it shows (an image or a GIF), typed or picked
// with the system's file chooser (zenity, services/FilePicker.qml: Settings hides meanwhile), or a folder's
// random one and when it changes (each dashboard open, each shell start, a timer), and a GIF's speed.
Column {
    id: root

    required property var entry
    signal edited(var options)

    readonly property var options: entry?.options ?? ({})

    function set(key: string, v: var) {
        const o = Object.assign({}, root.options);
        o[key] = v;
        root.edited(o);
    }

    // Settings closes while the system's chooser is open (the island would cover it), then comes back on
    // this Dwidget with the file or folder set (services/FilePicker.qml)
    readonly property var back: ({
            id: "settings",
            args: {
                page: "dashboard/layout"
            }
        })
    function setOn(uid: string, key: string, value: var) {
        Store.dashboard.widgets = Store.dashboard.widgets.map(w => {
            if (w.uid !== uid)
                return w;
            const o = Object.assign({}, w.options ?? {});
            o[key] = value;
            return Object.assign({}, w, {
                options: o
            });
        });
    }
    function browse() {
        const uid = root.entry?.uid ?? "";
        FilePicker.pick("Pick an image", [
            {
                name: "Images",
                patterns: ["*.png", "*.jpg", "*.jpeg", "*.webp", "*.gif", "*.svg", "*.bmp", "*.PNG", "*.JPG", "*.JPEG", "*.WEBP", "*.GIF"]
            }
        ], path => root.setOn(uid, "path", path), root.back);
        Store.appSet("settings", "layoutUid", uid);
    }
    function browseFolder() {
        const uid = root.entry?.uid ?? "";
        FilePicker.pickFolder("Pick a folder", path => root.setOn(uid, "folder", path), root.back);
        Store.appSet("settings", "layoutUid", uid);
    }
    readonly property bool fromFolder: options.source === "folder"

    width: parent?.width ?? 0
    spacing: 0

    StyledText {
        topPadding: Tokens.spacing.m
        bottomPadding: Tokens.spacing.xs
        text: "Image"
        font.pixelSize: Tokens.font.small
        font.weight: Font.Bold
        color: Colors.primary
    }
    SettingRow {
        width: root.width
        label: "Source"
        description: "One file, or a random one from a folder"
        Segmented {
            options: [
                {
                    value: "file",
                    label: "File"
                },
                {
                    value: "folder",
                    label: "Folder"
                }
            ]
            value: root.fromFolder ? "folder" : "file"
            onSelected: v => root.set("source", v)
        }
    }
    SettingRow {
        width: root.width
        stacked: true
        visible: !root.fromFolder
        label: "File"
        description: "A PNG, JPG, WebP, SVG or GIF (a GIF plays); a file without an extension works too"
        Row {
            spacing: Tokens.spacing.s

            TextField {
                width: Math.max(120, root.width - browse.width - Tokens.spacing.s)
                value: root.options.path ?? ""
                placeholder: "~/Pictures/image.png"
                onEdited: v => root.set("path", v.trim())
            }
            SmallButton {
                id: browse
                text: "Browse…"
                enabled: !FilePicker.busy
                onClicked: root.browse()
            }
        }
    }

    SettingRow {
        width: root.width
        stacked: true
        visible: root.fromFolder
        label: "Folder"
        description: "A random file from it, never the same one twice in a row"
        Row {
            spacing: Tokens.spacing.s

            TextField {
                width: Math.max(120, root.width - browseFolderButton.width - Tokens.spacing.s)
                value: root.options.folder ?? ""
                placeholder: "~/Pictures/Funny"
                onEdited: v => root.set("folder", v.trim())
            }
            SmallButton {
                id: browseFolderButton
                text: "Browse…"
                enabled: !FilePicker.busy
                onClicked: root.browseFolder()
            }
        }
    }
    SettingRow {
        width: root.width
        visible: root.fromFolder
        label: "Changes"
        description: "When it takes another one: each time the dashboard opens, each time the shell starts, or on a timer"
        Segmented {
            options: [
                {
                    value: "open",
                    label: "Each open"
                },
                {
                    value: "start",
                    label: "Each start"
                },
                {
                    value: "timer",
                    label: "Timer"
                }
            ]
            value: root.options.change || "open"
            onSelected: v => root.set("change", v)
        }
    }
    SettingRow {
        width: root.width
        visible: root.fromFolder && (root.options.change || "open") === "timer"
        label: "Every"
        Stepper {
            value: root.options.minutes ?? 30
            from: 1
            to: 1440
            step: 5
            suffix: " min"
            onEdited: v => root.set("minutes", v)
        }
    }

    SettingRow {
        width: root.width
        label: "Fit"
        description: "Crop fills it (cutting the rest), Fit shows it whole, Stretch fills it whole"
        Segmented {
            options: [
                {
                    value: "crop",
                    label: "Crop"
                },
                {
                    value: "fit",
                    label: "Fit"
                },
                {
                    value: "stretch",
                    label: "Stretch"
                }
            ]
            value: root.options.fit || "crop"
            onSelected: v => root.set("fit", v)
        }
    }
    SettingRow {
        width: root.width
        visible: (root.options.fit || "crop") === "crop"
        label: "Focus"
        description: "The part a crop keeps"
        Segmented {
            options: [
                {
                    value: "center",
                    label: "Center"
                },
                {
                    value: "top",
                    label: "Top"
                },
                {
                    value: "bottom",
                    label: "Bottom"
                },
                {
                    value: "left",
                    label: "Left"
                },
                {
                    value: "right",
                    label: "Right"
                }
            ]
            value: root.options.focus || "center"
            onSelected: v => root.set("focus", v)
        }
    }
    SettingRow {
        width: root.width
        label: "GIF speed"
        description: "How fast a GIF plays"
        Segmented {
            options: [0.25, 0.5, 1, 1.5, 2].map(v => ({
                        value: v,
                        label: v + "×"
                    }))
            value: root.options.speed ?? 1
            onSelected: v => root.set("speed", v)
        }
    }
}
