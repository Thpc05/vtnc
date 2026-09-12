import QtQuick
import "../Config"

// ═══════════════════════════════════════════
//  MEDIA ART — Capa com FALLBACK. Tenta qualquer URL (Spotify http,
//  thumb do YouTube, file://, data:…). Se vier vazia ou falhar o
//  carregamento, mostra um ícone de nota no lugar do quadrado morto.
//  É o que faz fontes fora do Spotify não ficarem com capa em branco.
// ═══════════════════════════════════════════
Rectangle {
    id: root

    property string source: ""
    property int glyphSize: 20

    radius: 8
    color: Theme.surface
    clip: true

    Image {
        id: img
        anchors.fill: parent
        source: root.source
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
    }

    Text {
        anchors.centerIn: parent
        visible: root.source === ""
            || img.status === Image.Error
            || img.status === Image.Null
        text: "󰝚"
        color: Theme.textMuted
        font { family: Theme.fontIcon; pixelSize: root.glyphSize }
    }
}
