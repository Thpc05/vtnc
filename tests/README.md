# tests

As quatro camadas da decisão 17.2:

1. **`unit/`** — lógica pura em JS, testada em node (`node --test
   tests/unit`). Cobre `core/grid.mjs` e `core/config-shape.mjs`.
2. **`qml/check-compile.sh`** — todo o QML compila. Roda sob
   `QT_QPA_PLATFORM=offscreen`, sem compositor: para exatamente no ponto
   esperado ("No PanelWindow backend loaded"), o que prova que todo import e
   referência de tipo antes disso já resolveu.
3. **`cli/contract.sh`** — contrato da CLI contra uma shell de verdade, no
   Hyprland aninhado (`tools/headless/nested.sh`). Também serve como teste
   de aceite dos seis critérios da 0.51.
4. **`visual/render-check.sh`** — renderiza uma page para PNG, para ser
   **olhada**, não comparada pixel a pixel. **Limitação conhecida:**
   `grabWindow()`/`grabToImage()` travam indefinidamente neste ambiente sob
   `QT_QPA_PLATFORM=offscreen` (testado com e sem sandbox, com os backends
   RHI/Quick em software, com `QSG_RENDER_LOOP=basic`) — nenhuma delas
   destravou. O script tem um timeout de 15s e falha visivelmente em vez de
   travar, mas a causa raiz não foi encontrada; pode ser uma limitação desta
   máquina/build do Qt, não do código do vtnc. Vale confirmar numa sessão
   interativa normal antes de assumir que é um bug daqui.

Nenhuma destas precisa de permissão ou da tela do Theo; 1, 2 e 4 nem
precisam de compositor nenhum.
