import QtQuick

// An entry of a K.Menu.
QtObject {
    required property string text
    property string icon
    property string trailingIcon
    property string activeIcon: icon
    property string activeText: text
    property var value

    signal clicked
}
