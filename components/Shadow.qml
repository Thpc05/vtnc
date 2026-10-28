import QtQuick
import QtQuick.Effects
import qs.theme

// A soft shadow under a layer (layer.effect: Shadow {}), in the scheme's shadow color.
// vtnc: was compat Config's theme shadow (the same values).
MultiEffect {
    shadowEnabled: true
    shadowHorizontalOffset: 0
    shadowVerticalOffset: 0
    shadowBlur: 1
    shadowColor: Colors.shadow
    shadowOpacity: 0.5
}
