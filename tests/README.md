# tests

As quatro camadas da decisão 17.2:

1. **`unit/`** — lógica pura em JS, testada em node (`node --test
   tests/unit`). Cobre `core/grid.mjs` e `core/config-shape.mjs`.
2. **`qml/check-compile.sh`** — todo o QML compila. Roda sob
   `QT_QPA_PLATFORM=offscreen`, sem compositor: para exatamente no ponto
   esperado ("No PanelWindow backend loaded"). Verificado na marra, quebrando
   `Default.qml` e `Page.qml` de propósito: o Qt reporta o erro real e omite
   a mensagem do PanelWindow, então o script acusa. Mas ele depende dessa
   ordem — se um dia as duas mensagens saírem juntas, ele dirá OK com o QML
   quebrado.
3. **`cli/contract.sh`** — contrato da CLI contra uma shell de verdade, no
   Hyprland aninhado (`tools/headless/nested.sh`). Também serve como teste
   de aceite dos seis critérios da 0.51.
4. **`visual/render-check.sh`** — renderiza uma page para PNG, para ser
   **olhada**, não comparada pixel a pixel. Sobe o aninhado sozinho, a menos
   que `NESTED_PID` já esteja no ambiente.

A camada 4 **precisa de compositor**: sob `QT_QPA_PLATFORM=offscreen` o
`grabToImage` nunca chama o callback de volta, com qualquer combinação de
`QT_QUICK_BACKEND` e `QSG_RENDER_LOOP`. Dentro do aninhado ele responde na
hora. Só as camadas 1 e 2 dispensam compositor.

Nenhuma delas precisa de permissão nem da tela do Theo.
