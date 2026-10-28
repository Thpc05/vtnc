import QtQuick
import Quickshell.Widgets
import qs.core
import qs.components
import qs.theme
import qs.kit as K
import qs.services
import "../controls"

// Presets (services/Presets.qml): the shell's style (Island, Dashboard, Appearance, with the
// wallpaper and colors) saved as a snapshot. Saving happens only here; the other pages offer Revert.
Page {
    id: page

    // the name typed for a new preset, and why it can't be used
    property string newName: ""
    property string newError: ""
    property bool withWallpaper: true
    // the preset waiting for "unsaved changes" confirmation, being renamed, being deleted
    property string pending: ""
    property string renaming: ""
    property string renameError: ""
    property string deleting: ""

    function tryApply(name: string) {
        // unsaved changes, or a setup that isn't in any preset: ask first
        if (Presets.modified || !Presets.activePreset) {
            pending = name;
            return;
        }
        applyClosing(name);
    }
    // Settings closes first, then the preset applies (on the idle island)
    function applyClosing(name: string) {
        Presets.applyAfterClose(name);
    }
    function saveNew() {
        newError = Presets.saveAs(newName, withWallpaper);
        if (newError === "")
            newName = "";
    }
    function schemeTitle(s: string): string {
        return (s || "").replace("scheme-", "").split("-").map(w => w ? w[0].toUpperCase() + w.slice(1) : "").join(" ");
    }

    Component.onCompleted: Presets.scan()

    Column {
        width: parent?.width ?? 0
        spacing: Tokens.spacing.l

        // the active preset and a new one side by side, every preset below
        Columns {
            Section {
                title: "Active"

                // the same card as in the list, with Revert / Save instead of the list's actions
                PresetRow {
                    visible: Presets.activePreset !== null
                    preset: Presets.activePreset ?? ({ name: "", config: {} })
                    current: true
                }
                SettingRow {
                    visible: Presets.activePreset === null
                    label: "No preset"
                    description: "Save the current setup as a new preset to come back to it"
                }
                SettingRow {
                    visible: Presets.lastMissing !== ""
                    label: "Wallpaper not found"
                    description: Presets.lastMissing + " is gone: the wallpaper shown was kept"
                }
            }

            Section {
                title: "New"

                SettingRow {
                    label: "Name"
                    description: page.newError !== "" ? page.newError : "The island, dashboard and appearance as they are now"

                    Row {
                        spacing: Tokens.spacing.s

                        TextField {
                            implicitWidth: 140
                            placeholder: "Preset name"
                            value: page.newName
                            // on every keystroke: Save is enabled as soon as there is a name
                            onTyped: v => {
                                page.newName = v;
                                page.newError = "";
                            }
                        }
                        SmallButton {
                            text: "Save"
                            accent: true
                            enabled: page.newName.trim() !== ""
                            onClicked: page.saveNew()
                        }
                    }
                }
                SettingRow {
                    label: "With wallpaper"
                    description: "Off: applying it keeps the wallpaper shown"
                    Switch {
                        checked: page.withWallpaper
                        onToggled: c => page.withWallpaper = c
                    }
                }
            }
        }

        Section {
            title: "Presets"

            SettingRow {
                visible: Presets.list.length === 0
                label: "No presets yet"
                description: "Save one in New"
            }
            Repeater {
                model: Presets.list

                PresetRow {
                    required property var modelData
                    preset: modelData
                }
            }
        }
    }

    // one preset: thumbnail, name, mode and scheme, actions; confirmations below
    component PresetRow: Column {
        id: row

        property var preset
        // the Active section's card: Revert / Save, no confirmations (the list's card has them)
        property bool current: false
        readonly property bool isActive: preset.name === Presets.active
        // Default: never saved over, renamed or deleted
        readonly property bool locked: Presets.isLocked(preset)
        readonly property var config: Presets.configOf(preset)
        readonly property var theme: config.appearance?.theme ?? {}
        // the preset's own wallpaper: none (or a missing one) leaves the thumbnail empty
        readonly property string wallpaper: Presets.wallpaperMissing(preset) ? "" : Presets.wallpaperOf(preset)
        // saved without a wallpaper, or with one that's gone
        readonly property string wallpaperNote: Presets.wallpaperOf(preset) === "" ? "no wallpaper" : Presets.wallpaperMissing(preset) ? "wallpaper missing" : ""

        width: parent?.width ?? 0
        spacing: Tokens.spacing.s
        topPadding: Tokens.spacing.s
        bottomPadding: Tokens.spacing.s

        Item {
            width: parent.width
            height: 48

            // the image fills the rounded rect (ClippingRectangle clips it to the corners); the active
            // border is a sibling on top, not a child: ClippingRectangle reparents its children into an
            // inner item (so `parent.radius` there is undefined) and would clip the stroke
            Item {
                id: thumb
                anchors.verticalCenter: parent.verticalCenter
                width: 72
                height: 44

                readonly property int radius: K.Kit.rounding.small

                ClippingRectangle {
                    anchors.fill: parent
                    radius: thumb.radius
                    color: K.Kit.expressive.off

                    Image {
                        anchors.fill: parent
                        visible: row.wallpaper !== ""
                        source: row.wallpaper !== "" ? Wallpapers.thumbFor(row.wallpaper) : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        sourceSize.width: 144
                    }
                }
                Rectangle {
                    anchors.fill: parent
                    visible: row.isActive
                    radius: thumb.radius
                    color: "transparent"
                    border.width: 2
                    border.color: Colors.primary
                }
            }
            Column {
                anchors.left: thumb.right
                anchors.leftMargin: Tokens.spacing.m
                anchors.right: actions.left
                anchors.rightMargin: Tokens.spacing.s
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Row {
                    spacing: Tokens.spacing.s
                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.preset.name
                        font.weight: Font.Bold
                        elide: Text.ElideRight
                    }
                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: row.isActive
                        text: Presets.modified ? "Active · modified" : "Active"
                        font.pixelSize: Tokens.font.small
                        color: Colors.primary
                    }
                }
                Row {
                    spacing: Tokens.spacing.xs
                    Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        icon: row.theme.light ? Icons.sun : Icons.moon
                        size: 12
                        color: Colors.outline
                    }
                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: (row.theme.light ? "Light" : "Dark") + " · " + page.schemeTitle(row.theme.scheme) + (row.wallpaperNote !== "" ? " · " + row.wallpaperNote : "")
                        font.pixelSize: Tokens.font.small
                        color: Colors.outline
                    }
                }
            }
            Row {
                id: actions
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: Tokens.spacing.xs

                SmallButton {
                    visible: row.current && Presets.modified
                    text: "Revert"
                    onClicked: Presets.revert("")
                }
                SmallButton {
                    visible: row.current && !row.locked
                    text: "Save"
                    accent: true
                    enabled: Presets.modified
                    onClicked: Presets.save()
                }
                SmallButton {
                    visible: !row.current && (!row.isActive || Presets.modified)
                    text: row.isActive ? "Reapply" : "Apply"
                    accent: !row.isActive
                    onClicked: row.isActive ? Presets.revertAfterClose() : page.tryApply(row.preset.name)
                }
                SmallButton {
                    visible: !row.current && !row.locked
                    text: "Rename"
                    onClicked: {
                        page.renameError = "";
                        page.renaming = page.renaming === row.preset.name ? "" : row.preset.name;
                    }
                }
                SmallButton {
                    visible: !row.current
                    text: "Duplicate"
                    onClicked: Presets.duplicate(row.preset.name)
                }
                SmallButton {
                    visible: !row.current && !row.locked
                    text: "Delete"
                    danger: page.deleting === row.preset.name
                    onClicked: page.deleting = page.deleting === row.preset.name ? "" : row.preset.name
                }
            }
        }

        // the active one's changes
        Confirm {
            visible: row.current && Presets.modified
            message: "Changed: " + Presets.modifiedParts.map(p => Presets.partTitles[p]).join(" · ") + (row.locked ? ". Default can't be updated: save as a new preset to keep it" : "")
        }

        // apply with unsaved changes
        Confirm {
            visible: !row.current && page.pending === row.preset.name
            message: Presets.activePreset ? `Unsaved changes to ${Presets.active} will be lost` : "The current setup isn't in a preset: it will be lost"

            SmallButton {
                visible: Presets.activePreset !== null && !Presets.isLocked(Presets.activePreset)
                text: "Save and apply"
                accent: true
                onClicked: {
                    Presets.save();
                    page.applyClosing(page.pending);
                    page.pending = "";
                }
            }
            SmallButton {
                text: Presets.activePreset ? "Discard and apply" : "Apply anyway"
                onClicked: {
                    page.applyClosing(page.pending);
                    page.pending = "";
                }
            }
            SmallButton {
                text: "Cancel"
                onClicked: page.pending = ""
            }
        }

        // rename
        Confirm {
            visible: !row.current && page.renaming === row.preset.name
            message: page.renameError !== "" ? page.renameError : "New name (Enter)"

            TextField {
                implicitWidth: 160
                value: row.preset.name
                onEdited: v => {
                    page.renameError = Presets.rename(row.preset.name, v);
                    if (page.renameError === "")
                        page.renaming = "";
                }
            }
            SmallButton {
                text: "Cancel"
                onClicked: page.renaming = ""
            }
        }

        // delete
        Confirm {
            visible: !row.current && page.deleting === row.preset.name
            message: `Delete ${row.preset.name}? The file is removed`

            SmallButton {
                text: "Delete"
                danger: true
                onClicked: {
                    Presets.remove(page.deleting);
                    page.deleting = "";
                }
            }
            SmallButton {
                text: "Cancel"
                onClicked: page.deleting = ""
            }
        }
    }

    // a message with its buttons, under a preset
    component Confirm: Item {
        id: confirm

        property string message
        default property alias buttons: buttonRow.data

        width: parent?.width ?? 0
        height: visible ? Math.max(30, buttonRow.implicitHeight) : 0

        StyledText {
            anchors.left: parent.left
            anchors.leftMargin: 72 + Tokens.spacing.m
            anchors.right: buttonRow.left
            anchors.rightMargin: Tokens.spacing.s
            anchors.verticalCenter: parent.verticalCenter
            text: confirm.message
            font.pixelSize: Tokens.font.small
            color: Colors.overSurfaceVariant
            elide: Text.ElideRight
        }
        Row {
            id: buttonRow
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Tokens.spacing.xs
        }
    }
}
