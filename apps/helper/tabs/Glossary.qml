import QtQuick
import ".."
import "../glossary.js" as GlossaryData

// Helper → Glossary (2026-10-17): vtnc's words (glossary.js).
HelperList {
    placeholder: "Search terms…"
    keyWidth: 180
    wrap: true
    heroIcon: "menu_book"
    heroShape: "cookie12"
    heroTitle: "Glossary"
    heroText: "vtnc has a few words of its own: the island, its Iwidgets, the dashboard's Dwidgets and Qwidgets, the looks. What each one means, in a sentence."
    sections: [{
            title: "",
            rows: GlossaryData.TERMS.map(t => ({
                        place: t.term,
                        text: t.text
                    }))
        }]

    function opened() {
        reset();
    }
}
