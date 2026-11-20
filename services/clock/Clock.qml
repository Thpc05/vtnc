import QtQml

// One clock in the whole shell (decision 15.2): a single Timer here, not
// one per widget that shows time. ServiceRegistry creates exactly one of
// these while anyone needs it, and every clock widget — in any island, on
// any screen — reads this same instance's `time`.
QtObject {
    id: root

    property string time: ""

    function _tick() {
        const now = new Date();
        const pad = (n) => (n < 10 ? "0" + n : "" + n);
        root.time = pad(now.getHours()) + ":" + pad(now.getMinutes()) + ":" + pad(now.getSeconds());
    }

    Component.onCompleted: root._tick()

    // QtObject has no default property for children (unlike Item) — the
    // Timer has to be a named property, not a bare child block.
    property Timer _ticker: Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root._tick()
    }
}
