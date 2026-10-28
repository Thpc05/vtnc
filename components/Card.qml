import QtQuick
import qs.theme
import qs.kit as K

// A card on the shell's surface ladder (caelestia's: surfaceContainer, rounding large);
// `inner` = one level up (off, rounding medium), for elements inside a card.
Rectangle {
    property bool inner: false

    radius: inner ? K.Kit.rounding.medium : K.Kit.rounding.large
    color: inner ? K.Kit.expressive.off : K.Kit.expressive.container

    Behavior on color {
        K.CAnim {}
    }
}
