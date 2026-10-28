import QtQuick
import qs.dwidgets
import qs.dwidgets.quick
import "../catalog.js" as DCatalog

// The apps' summaries on the dashboard (2026-10-17, user; Dino run 2026-10-27): Notifications, Clipboard,
// Notes and Dino run, one
// component with a `kind` (as the toggles' qid), in the Iwidget family (shapes · tones · tone, each also on
// the card), drawn by SummaryView from the kind's source. 1x1 / 2x1 / 1x2 a badge (the count; a click opens
// the app), 2x2 and up a list (a click on an item acts: runs the notification, copies the entry, opens the
// note). Options: color (the tones' colour role), randomShapes.
Dwidget {
    id: root

    // notifications · clipboard · notes · dino
    property string kind: "notifications"

    property QtObject source: null
    Component.onCompleted: source = ({
            clipboard: clipboardSource,
            notes: notesSource,
            dino: dinoSource
        }[kind] ?? notificationsSource).createObject(root)
    Component.onDestruction: source?.destroy()

    // each open of the dashboard reads them again (the notes on disk, the clipboard history)
    readonly property int opens: DashboardShape.opens
    onOpensChanged: source?.opened()

    readonly property bool card: DCatalog.isCard(root.kind, root.style)
    DwidgetCard {
        id: cardHost
        anchors.fill: parent
        card: root.card
    }
    ToneColors {
        id: colors
        pal: cardHost.pal
        role: root.options?.color || "primary"
    }

    Loader {
        anchors.fill: parent
        anchors.margins: cardHost.pad
        active: root.source !== null
        sourceComponent: SummaryView {
            source: root.source
            look: DCatalog.baseStyle(root.kind, root.style)
            pal: cardHost.pal
            tone: colors.tone
            overTone: colors.overTone
            randomShapes: root.options?.randomShapes ?? true
            interactive: !root.editing
            layout: root.size.w * root.size.h <= 2 ? "badge" : "list"
            targetWidth: root.targetWidth - 2 * cardHost.padFor(root.targetWidth, root.targetHeight)
            targetHeight: root.targetHeight - 2 * cardHost.padFor(root.targetWidth, root.targetHeight)
        }
    }

    Component {
        id: dinoSource
        DinoSource {}
    }
    Component {
        id: notificationsSource
        NotificationsSource {}
    }
    Component {
        id: clipboardSource
        ClipboardSource {}
    }
    Component {
        id: notesSource
        NotesSource {}
    }
}
