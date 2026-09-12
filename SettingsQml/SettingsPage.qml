import QtQuick
import "../ConfigValues"

// ═══════════════════════════════════════════
//  SETTINGS PAGE — Contrato de uma página do config.
//  Mesmo padrão de Island ↔ IslandFace: a janela não conhece nenhuma
//  página concreta, só este contrato. Adicionar uma página = criar o
//  arquivo + 1 linha na lista do SettingsWindow.
//
//  A rolagem e as margens são da janela; a página só empilha grupos.
// ═══════════════════════════════════════════
Column {
    id: page

    // Nome na barra lateral
    property string title: ""
    // Glyph (nerd font) do ícone redondo da barra lateral
    property string icon: ""

    spacing: 18
}
