# settings

A Settings: uma janela comum do Hyprland, não uma superfície de layer-shell
(decisão 1d.6) — segue as regras de posicionamento de qualquer app e pode
ser morta por super+q. Verificável: aparece em `hyprctl clients`, nunca em
`hyprctl layers`.

- `Settings.qml` — a casca: a janela (`Window`, não `PanelWindow`) e a
  barra lateral, sem busca (decisão 8.4), com as dez páginas da decisão
  8.1. Só "Islands" está construída na 0.503; as outras nove mostram que
  ainda não existem.
- O conteúdo de cada página é uma `Page` real (`../page/`), montada com
  widgets reais (decisão 8.3) — a settings não inventa um segundo
  mecanismo de layout. "Islands" usa `widgets/island-editor`; as outras
  nove usam `widgets/not-built`.
- Edição é sempre ao vivo, sem botão de salvar (decisão 6.3 — salvar só
  existe em Presets, fora de escopo aqui).

**A afirmação que esta pasta prova**: a Settings não escreve configuração
por conta própria. Toda mudança passa por `core/CliRunner.qml`, que chama o
binário `cli/vtnc` de verdade — nunca `core/Config.qml` diretamente. É por
isso que `widgets/island-editor` lê de `Config` (para refletir o estado ao
vivo) mas só escreve via `CliRunner.run(...)`.

A unidade de célula daqui (`Settings.cellPx`) é só um tamanho de painel
conveniente dentro de uma janela comum — não tem relação com a grade da
tela (`core/grid.mjs`), que é por monitor e não se aplica a uma janela.
