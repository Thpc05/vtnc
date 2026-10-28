import QtQuick
import qs.components
import qs.theme
import "../../controls"

// The look options of a Quick configs / toggle / Sliders entry (its `options`, 2026-10-11), in the
// Layout side panel: the Two tones / Tone colour, the gap (Quick configs), the icons' weight, the labels
// (the name and state beside the marks: by the size, always, or never); Sliders: wavy and the percent;
// Calendar: the title (month) and the weekdays; Media: art, wavy, times; the Mixer toggle: what it shows
// (output · input · apps); Clock: seconds, 24 h, the date; Visualizer: the bars and always show (2026-10-27).
Column {
    id: root

    required property var entry
    property bool showGap: true
    property bool showWeight: true
    property bool showLabels: true
    // Sliders: the wave while music plays and the percent
    property bool showSlider: false
    // Calendar: the title and weekday switches
    property bool showCalendar: false
    // the Mixer toggle: the parts of its panel
    property bool showMixer: false
    // Clock: seconds, 24 h, the date
    property bool showClock: false
    // Visualizer: the bars, always show
    property bool showVisualizer: false
    // Media: the art, the wave and the times
    property bool showMedia: false
    // Random shapes (the Shapes look's marks; Quick configs, the toggles, Calendar)
    property bool showShapes: true
    // the Random shapes row's text (empty: the look's own)
    property string shapesHint: ""
    // the weight stepper's top and what it weighs
    property int weightTo: 1500
    property string weightHint: "The icons' (Auto: the look's)"
    signal edited(var options)

    readonly property var options: entry?.options ?? ({})

    function set(key: string, v: var) {
        const o = Object.assign({}, root.options);
        o[key] = v;
        root.edited(o);
    }

    width: parent?.width ?? 0
    spacing: 0

    StyledText {
        topPadding: Tokens.spacing.m
        bottomPadding: Tokens.spacing.xs
        text: "Look"
        font.pixelSize: Tokens.font.small
        font.weight: Font.Bold
        color: Colors.primary
    }
    SettingRow {
        width: root.width
        label: "Color"
        description: "Two tones and Tone: the on marks and the text in it, the off ones a weak tone of it"
        Segmented {
            options: [
                {
                    value: "primary",
                    label: "Primary"
                },
                {
                    value: "surface",
                    label: "Surface"
                },
                {
                    value: "variant",
                    label: "Muted"
                },
                {
                    value: "secondary",
                    label: "Secondary"
                },
                {
                    value: "tertiary",
                    label: "Tertiary"
                }
            ]
            value: root.options.color || "primary"
            onSelected: v => root.set("color", v)
        }
    }
    SettingRow {
        width: root.width
        visible: root.showGap
        label: "Gap"
        Stepper {
            value: root.options.gap ?? 0
            from: 0
            to: 32
            step: 2
            firstValue: 2
            specialValueText: "Auto"
            suffix: " px"
            onEdited: v => root.set("gap", v)
        }
    }
    SettingRow {
        width: root.width
        visible: root.showWeight
        label: "Weight"
        description: root.weightHint
        Stepper {
            value: root.options.weight ?? 0
            from: 0
            to: root.weightTo
            step: 100
            firstValue: 300
            specialValueText: "Auto"
            onEdited: v => root.set("weight", v)
        }
    }
    SettingRow {
        width: root.width
        visible: root.showShapes
        label: "Random shapes"
        description: root.shapesHint !== "" ? root.shapesHint : root.showCalendar ? "Shapes: today on a random shape each time the dashboard opens (in sync with the others). Off: one shape per day" : "Shapes: the on marks take a random shape each time the dashboard opens (in sync with the others) and a new one when one turns on, connects or disconnects. Off: circles"
        Switch {
            checked: root.options.randomShapes ?? true
            onToggled: c => root.set("randomShapes", c)
        }
    }
    SettingRow {
        width: root.width
        visible: root.showSlider || root.showMedia
        label: "Wavy"
        description: root.showMedia ? "The progress waves while playing (Disc: its ring)" : "The tracks wave while music plays (thinning meanwhile)"
        Switch {
            checked: root.options.wavy ?? true
            onToggled: c => root.set("wavy", c)
        }
    }
    SettingRow {
        width: root.width
        visible: root.showSlider
        label: "Percent"
        description: "The value beside each slider"
        Switch {
            checked: root.options.number ?? true
            onToggled: c => root.set("number", c)
        }
    }
    SettingRow {
        width: root.width
        visible: root.showMedia
        label: "Art"
        description: "The cover (Disc: the record)"
        Switch {
            checked: root.options.art ?? true
            onToggled: c => root.set("art", c)
        }
    }
    SettingRow {
        width: root.width
        visible: root.showMedia
        label: "Times"
        description: "The position and length beside the controls"
        Switch {
            checked: root.options.times ?? true
            onToggled: c => root.set("times", c)
        }
    }
    SettingRow {
        width: root.width
        visible: root.showCalendar
        label: "Title"
        description: "The month (with today alone: the month's name)"
        Switch {
            checked: root.options.title ?? true
            onToggled: c => root.set("title", c)
        }
    }
    SettingRow {
        width: root.width
        visible: root.showCalendar
        label: "Weekdays"
        description: "The weekdays' letters (with today alone: its name)"
        Switch {
            checked: root.options.weekdays ?? true
            onToggled: c => root.set("weekdays", c)
        }
    }
    SettingRow {
        width: root.width
        visible: root.showLabels
        label: "Labels"
        description: "The name and state beside the marks: when the size has room, whenever a row fits, or never"
        Segmented {
            options: [
                {
                    value: "auto",
                    label: "Auto"
                },
                {
                    value: "on",
                    label: "On"
                },
                {
                    value: "off",
                    label: "Off"
                }
            ]
            value: root.options.labels || "auto"
            onSelected: v => root.set("labels", v)
        }
    }

    // the Mixer toggle's panel parts (options.show; at least one stays on)
    Repeater {
        model: root.showMixer ? [
            {
                key: "output",
                label: "Output",
                description: "The output devices"
            },
            {
                key: "input",
                label: "Input",
                description: "The microphones"
            },
            {
                key: "apps",
                label: "Apps",
                description: "A volume per app playing"
            }
        ] : []

        SettingRow {
            id: partRow
            required property var modelData
            readonly property var parts: root.options.show ?? ["output", "input", "apps"]
            width: root.width
            label: modelData.label
            description: modelData.description
            Switch {
                checked: partRow.parts.includes(partRow.modelData.key)
                onToggled: c => {
                    const parts = partRow.parts.filter(k => k !== partRow.modelData.key).concat(c ? [partRow.modelData.key] : []);
                    if (parts.length > 0)
                        root.set("show", ["output", "input", "apps"].filter(k => parts.includes(k)));
                }
            }
        }
    }

    // Clock
    SettingRow {
        width: root.width
        visible: root.showClock
        label: "24-hour"
        Switch {
            checked: root.options.h24 ?? true
            onToggled: c => root.set("h24", c)
        }
    }
    SettingRow {
        width: root.width
        visible: root.showClock
        label: "Seconds"
        Switch {
            checked: root.options.seconds ?? false
            onToggled: c => root.set("seconds", c)
        }
    }
    SettingRow {
        width: root.width
        visible: root.showClock
        label: "Date"
        description: "Under the time when there's room"
        Switch {
            checked: root.options.date ?? true
            onToggled: c => root.set("date", c)
        }
    }

    // Visualizer
    SettingRow {
        width: root.width
        visible: root.showVisualizer && !(root.entry?.idle?.style ?? "").startsWith("shapes")
        label: "Bars"
        Stepper {
            value: root.options.bars ?? 16
            from: 4
            to: 48
            step: 2
            onEdited: v => root.set("bars", v)
        }
    }
    SettingRow {
        width: root.width
        visible: root.showVisualizer && !(root.entry?.idle?.style ?? "").startsWith("bars")
        label: "Threshold"
        description: "The level it reacts from: Shapes start moving, Dots light up past it (higher: only the loud parts)"
        Stepper {
            value: root.options.threshold ?? 0
            from: 0
            to: 90
            step: 5
            suffix: " %"
            onEdited: v => root.set("threshold", v)
        }
    }
    SettingRow {
        width: root.width
        visible: root.showVisualizer && (root.entry?.idle?.style ?? "").startsWith("shapes")
        label: "Sensitivity"
        description: "How strong a bass hit must be to count as a beat (high: more beats)"
        Segmented {
            options: [
                {
                    value: "low",
                    label: "Low"
                },
                {
                    value: "medium",
                    label: "Medium"
                },
                {
                    value: "high",
                    label: "High"
                }
            ]
            value: root.options.sensitivity || "medium"
            onSelected: v => root.set("sensitivity", v)
        }
    }
    SettingRow {
        width: root.width
        visible: root.showVisualizer && (root.entry?.idle?.style ?? "").startsWith("shapes")
        label: "Shape trigger"
        description: "How much the bass must jump over its average to change the shape (lower: more changes; the pulse keeps Sensitivity)"
        Stepper {
            value: root.options.shapeTrigger ?? 35
            from: 5
            to: 100
            step: 5
            suffix: " %"
            onEdited: v => root.set("shapeTrigger", v)
        }
    }
    SettingRow {
        width: root.width
        visible: root.showVisualizer && (root.entry?.idle?.style ?? "").startsWith("shapes")
        label: "Pulse"
        description: "How much the shape grows with the music and on each beat"
        Segmented {
            options: [
                {
                    value: "subtle",
                    label: "Subtle"
                },
                {
                    value: "normal",
                    label: "Normal"
                },
                {
                    value: "strong",
                    label: "Strong"
                }
            ]
            value: root.options.pulse || "normal"
            onSelected: v => root.set("pulse", v)
        }
    }
    SettingRow {
        width: root.width
        visible: root.showVisualizer && (root.entry?.idle?.style ?? "").startsWith("shapes")
        label: "Shape changes"
        description: "The least time between two shapes"
        Segmented {
            options: [
                {
                    value: "calm",
                    label: "Calm"
                },
                {
                    value: "normal",
                    label: "Normal"
                },
                {
                    value: "lively",
                    label: "Lively"
                }
            ]
            value: root.options.morph || "normal"
            onSelected: v => root.set("morph", v)
        }
    }
    SettingRow {
        width: root.width
        visible: root.showVisualizer
        label: "Always show"
        description: "Flat while nothing plays (off: it fades out)"
        Switch {
            checked: root.options.alwaysShow ?? true
            onToggled: c => root.set("alwaysShow", c)
        }
    }
}
