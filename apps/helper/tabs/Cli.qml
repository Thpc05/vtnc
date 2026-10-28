import QtQuick
import ".."

// Helper → CLI (2026-10-17): the future `vtnc` command line (stage R3 / 9). Blank until it exists; the IPC
// tab has what works today.
HelperList {
    searchable: false
    heroIcon: "terminal"
    heroShape: "sunny"
    heroTitle: "vtnc CLI"
    heroText: "A <b>vtnc</b> command for your terminal and scripts is on the way: open apps, switch presets and wallpapers, change settings. Its commands will be listed here.<br>Until then, the <b>IPC</b> tab has everything the shell answers today."

    function opened() {
        reset();
    }
}
