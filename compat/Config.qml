pragma Singleton

import QtQuick
import Quickshell
import qs.core
import qs.theme
import "themeDefaults.js" as ThemeDefaults

// Compat Config singleton: exposes the keys the compat-based code reads,
// backed by vtnc's Store (core/STATE.md). Keys vtnc doesn't configure keep fixed defaults.
Singleton {
    id: root

    readonly property var themeData: ThemeDefaults.data

    // --- root-level aliases ---
    readonly property int roundness: Tokens.roundness
    readonly property int animDuration: Tokens.anim.duration
    readonly property string defaultFont: Store.theme.font
    readonly property bool oledMode: !Store.theme.light
    readonly property bool lightMode: Store.theme.light
    // the attached notch is named "default"
    readonly property string notchTheme: Store.island.style === "island" ? "island" : "default"
    readonly property string notchPosition: "top"
    readonly property bool showBackground: true

    readonly property QtObject theme: QtObject {
        readonly property string font: Store.theme.font
        readonly property int fontSize: Tokens.font.base
        readonly property string monoFont: Store.theme.monoFont
        readonly property int monoFontSize: Tokens.font.base
        readonly property bool oledMode: root.oledMode
        readonly property bool lightMode: root.lightMode
        readonly property int roundness: root.roundness
        readonly property int animDuration: root.animDuration
        readonly property bool tintIcons: false

        readonly property real shadowOpacity: root.themeData.shadowOpacity
        readonly property string shadowColor: root.themeData.shadowColor
        readonly property real shadowXOffset: root.themeData.shadowXOffset
        readonly property real shadowYOffset: root.themeData.shadowYOffset
        readonly property real shadowBlur: root.themeData.shadowBlur

        readonly property var srBg: root.themeData.srBg
        readonly property var srPopup: root.themeData.srPopup
        readonly property var srInternalBg: root.themeData.srInternalBg
        readonly property var srBarBg: root.themeData.srBarBg
        readonly property var srPane: root.themeData.srPane
        readonly property var srCommon: root.themeData.srCommon
        readonly property var srFocus: root.themeData.srFocus
        readonly property var srPrimary: root.themeData.srPrimary
        readonly property var srPrimaryFocus: root.themeData.srPrimaryFocus
        readonly property var srOverPrimary: root.themeData.srOverPrimary
        readonly property var srSecondary: root.themeData.srSecondary
        readonly property var srSecondaryFocus: root.themeData.srSecondaryFocus
        readonly property var srOverSecondary: root.themeData.srOverSecondary
        readonly property var srTertiary: root.themeData.srTertiary
        readonly property var srTertiaryFocus: root.themeData.srTertiaryFocus
        readonly property var srOverTertiary: root.themeData.srOverTertiary
        readonly property var srError: root.themeData.srError
        readonly property var srErrorFocus: root.themeData.srErrorFocus
        readonly property var srOverError: root.themeData.srOverError
    }

    readonly property QtObject performance: QtObject {
        readonly property bool dashboardPersistTabs: true
        readonly property int dashboardMaxPersistentTabs: 1
    }

    readonly property QtObject notch: QtObject {
        readonly property string theme: root.notchTheme
        readonly property string position: root.notchPosition
        readonly property bool keepHidden: false
        readonly property int hoverRegionHeight: 8
        // vtnc expands the island on hover itself; the CompactPlayer's own 1s hover expansion stays off
        readonly property bool disableHoverExpansion: true
        readonly property string noMediaDisplay: "userHost"
        readonly property string customText: "vtnc"
    }

    readonly property QtObject bar: QtObject {
        readonly property bool enableFirefoxPlayer: Store.media.enableFirefoxPlayer
        readonly property string position: "top"
        readonly property bool frameEnabled: false
    }

    readonly property QtObject weather: QtObject {
        readonly property string unit: "C"
    }

    readonly property QtObject system: QtObject {
        readonly property string language: "en"
    }

    // --- color helpers ---
    function isHexColor(colorValue) {
        if (!colorValue || typeof colorValue !== 'string')
            return false;
        const normalized = colorValue.toLowerCase().trim();
        return normalized.startsWith('#') || normalized.startsWith('rgb');
    }

    function resolveColor(colorValue) {
        if (!colorValue) return "transparent"; // Fallback

        if (isHexColor(colorValue)) {
            return colorValue;
        }

        // Check Colors singleton
        if (typeof Colors === 'undefined' || !Colors) return "transparent";

        return Colors[colorValue] || "transparent";
    }

    function resolveColorWithOpacity(colorValue, opacity) {
        if (!colorValue) return Qt.rgba(0,0,0,0);

        const color = isHexColor(colorValue) ? Qt.color(colorValue) : (Colors[colorValue] || Qt.color("transparent"));
        return Qt.rgba(color.r, color.g, color.b, opacity);
    }
}
