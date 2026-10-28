import QtQuick
import qs.kit as K
import "qwidgets.js" as Catalog

// A Qwidget's input, shared by every Quick configs style: a click toggles it (runs an action, opens
// an app; the Mixer opens its panel instead), a right click opens its panel, or does its `alternate`
// (the colour scheme goes back). `qid` is the instance's key ("caffeine#2"). Ripple and hover as a K.StateLayer.
K.StateLayer {
    id: root

    property string qid
    property QtObject q: null
    signal openPanel(string qid)

    acceptedButtons: Qt.LeftButton | Qt.RightButton
    disabled: !(q?.available ?? false)
    onClicked: m => {
        if (m.button === Qt.RightButton) {
            if (Catalog.QWIDGETS[Catalog.idOf(root.qid)]?.panel)
                root.openPanel(root.qid);
            else
                root.q?.alternate?.();
        } else if (root.q?.opensPanel) {
            root.openPanel(root.qid);
        } else {
            root.q?.toggle();
        }
    }
}
