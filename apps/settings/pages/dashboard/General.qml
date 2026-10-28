import QtQuick
import qs.core
import qs.theme
import qs.components
import "../../controls"

// Dashboard → General: the grid (cell size, gap), how an expanding Dwidget makes room, and a demo layout for
// comparing the expand modes. The layout itself is edited in Dashboard → Layout (Layout.qml)
// (dwidgets/README.md).
Page {
    id: page


    // placeholders at the corners and in the middle (each expands on click to 4×3, the catalog's) and
    // the Wi-Fi toggle (double click to its list), for comparing the expand modes
    readonly property var demo: {
        const e = (id, uid, x, y, size, style) => Object.assign(DwidgetRegistry.defaultEntry(id, uid, x, y), size ? {
            idle: {
                style: style ?? "box",
                size: size
            }
        } : {});
        return [e("placeholder", "demo-a", 0, 0, "2x2"), e("placeholder", "demo-b", 2, 0, "2x1"), e("placeholder", "demo-c", 4, 0, "1x2", "tall"), e("placeholder", "demo-d", 5, 0, "1x1"), e("placeholder", "demo-e", 2, 1, "2x1"), e("placeholder", "demo-f", 5, 1, "1x1"), e("wifi", "demo-wifi", 0, 2), e("placeholder", "demo-g", 3, 2, "3x2"), e("placeholder", "demo-h", 0, 3, "1x1"), e("placeholder", "demo-i", 1, 3, "2x1")];
    }

    function setWidgets(list) {
        Store.dashboard.widgets = JSON.parse(JSON.stringify(list));
    }

    // the style gallery: every Dwidget (not the debug ones) in each of its styles, side by side at
    // the style's first size, packed in rows of `cols` cells
    readonly property var styleDemo: {
        const cols = 12;
        const out = [];
        let x = 0;
        let y = 0;
        let rowH = 0;
        const all = DwidgetRegistry.widgets;
        for (const id in all) {
            if (all[id].debug)
                continue;
            for (const st of all[id].styles) {
                const z = DwidgetRegistry.parseSize(st.sizes[0]);
                if (!z)
                    continue;
                if (x + z.w > cols) {
                    x = 0;
                    y += rowH;
                    rowH = 0;
                }
                const mode = {
                    style: st.id,
                    size: st.sizes[0]
                };
                out.push(Object.assign(DwidgetRegistry.defaultEntry(id, "style-" + id + "-" + st.id, x, y), {
                    idle: mode
                }));
                x += z.w;
                rowH = Math.max(rowH, z.h);
            }
        }
        return out;
    }

    // (Revert, at the page's top, brings the user's layout back; Restore / Factory layout removed 2026-10-17)
    function showDemo(list) {
        page.setWidgets(list ?? page.demo);
    }

    Columns {
        Section {
            title: "Grid"

            SettingRow {
                label: "Expand mode"
                description: "How a Dwidget that expands (the Wi-Fi and Bluetooth toggles) makes room: over its neighbours, pushing them down, or taking the whole dashboard"
                Segmented {
                    options: [
                        {
                            value: "over",
                            label: "Over"
                        },
                        {
                            value: "push",
                            label: "Push"
                        },
                        {
                            value: "takeover",
                            label: "Take over"
                        }
                    ]
                    value: Store.dashboard.expandMode
                    onSelected: v => Store.dashboard.expandMode = v
                }
            }
            SettingRow {
                label: "Cell size"
                description: "Every Dwidget spans a whole number of cells"
                Stepper {
                    value: Store.dashboard.cell
                    from: 48
                    to: 160
                    step: 4
                    suffix: " px"
                    onEdited: v => Store.dashboard.cell = v
                }
            }
            SettingRow {
                label: "Gap"
                description: "Space between cells"
                Stepper {
                    value: Store.dashboard.gap
                    from: 0
                    to: 24
                    step: 1
                    suffix: " px"
                    onEdited: v => Store.dashboard.gap = v
                }
            }
        }

        Section {
            title: "Layout"

            SettingRow {
                label: "Demo layout"
                description: "Placeholders that expand on click and the Wi-Fi toggle (double click for its list), for comparing the expand modes. Revert (top right) brings your layout back"
                IconButton {
                    icon: Icons.squaresFour
                    onClicked: page.showDemo()
                }
            }
            SettingRow {
                label: "Style demo"
                description: "Every Dwidget in each of its styles, side by side, for comparing them. Revert (top right) brings your layout back"
                IconButton {
                    icon: Icons.paintBrush
                    onClicked: page.showDemo(page.styleDemo)
                }
            }
        }
    }
}
