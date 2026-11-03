.pragma library

// The Media Dwidget (Widget.qml, MediaView.qml). The Iwidget family (2026-10-11, redone from scratch):
// shapes, two tones, tone and disc (the extra: a turning record in its wavy ring, as the island's),
// each also on the card.

// the sizes (redone 2026-10-11): a strip (3x1…6x1), 2x2, the art at the left (3x2…6x2, 4x3, 5x3, 6x3),
// the art on top (3x3, 3x4, 4x4, 5x4)
var SIZES = ["4x2", "3x1", "4x1", "5x1", "6x1", "2x2", "3x2", "5x2", "6x2", "3x3", "4x3", "5x3", "6x3", "3x4", "4x4", "5x4"];

var meta = {
    title: "Media",
    icon: "player",
    styles: [
        { id: "shapes", title: "Shapes", sizes: SIZES },
        { id: "tones", title: "Two tones", sizes: SIZES },
        { id: "tone", title: "Tone", sizes: SIZES },
        { id: "disc", title: "Disc", sizes: SIZES }
    ],
    cards: ["shapes", "tones", "tone", "disc"],
    defaults: { idle: { style: "shapes", size: "4x2" }, options: {} },
    // the 2026-10-08 looks: Cover and Android drew on a card, Type was two tones; the old "disc" (the
    // card one) keeps its id and becomes the no-card Disc
    renames: { cover: "shapesCard", android: "shapesCard", discNoCard: "disc", typeNoCard: "tones", type: "tonesCard" }
};
