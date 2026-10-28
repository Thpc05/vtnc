import QtQuick
import qs.core
import "../../controls"

// Apps → Tools (2026-10-27, from System): the tools app's hints, where screenshots and recordings go, the
// recording frame rate and the OCR language.
Page {
    Section {
        title: "App"

        SettingRow {
            label: "Hints"
            description: "Label under the buttons"
            Switch {
                checked: Store.hints.tools
                onToggled: c => Store.hints.tools = c
            }
        }
    }
    Section {
        title: "Screen tools"

        SettingRow {
            label: "Screenshots folder"
            TextField {
                value: Store.tools.screenshotsDir
                mono: true
                onEdited: v => Store.tools.screenshotsDir = v
            }
        }
        SettingRow {
            label: "Recordings folder"
            TextField {
                value: Store.tools.recordingsDir
                mono: true
                onEdited: v => Store.tools.recordingsDir = v
            }
        }
        SettingRow {
            label: "Recording FPS"
            Segmented {
                options: [30, 60, 120].map(f => ({
                            value: f,
                            label: String(f)
                        }))
                value: Store.tools.recordFps
                onSelected: v => Store.tools.recordFps = v
            }
        }
        SettingRow {
            label: "OCR language"
            description: "Tesseract language code(s), e.g. eng or eng+spa"
            TextField {
                implicitWidth: 120
                value: Store.tools.ocrLang
                mono: true
                onEdited: v => Store.tools.ocrLang = v
            }
        }
    }
}
