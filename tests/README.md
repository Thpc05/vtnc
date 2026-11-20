# tests

As quatro camadas da decisão 17.2:

1. **`unit/`** — lógica pura em JS, testada em node (`node --test
   tests/unit`). Cobre `core/grid.mjs` e `core/config-shape.mjs`, incluindo
   `validateIslandSet` (0.502: a validação do `set` da CLI).
2. **`qml/check-compile.sh`** — todo o QML compila. Roda sob
   `QT_QPA_PLATFORM=offscreen`, sem compositor: para exatamente no ponto
   esperado ("No PanelWindow backend loaded"). Verificado na marra, quebrando
   `Default.qml` e `Page.qml` de propósito: o Qt reporta o erro real e omite
   a mensagem do PanelWindow, então o script acusa. Mas ele depende dessa
   ordem — se um dia as duas mensagens saírem juntas, ele dirá OK com o QML
   quebrado.
3. **`cli/contract.sh`** — contrato da CLI contra uma shell de verdade, no
   Hyprland aninhado (`tools/headless/nested.sh`). Serve como teste de
   aceite dos seis critérios da 0.501 e, agora, dos seis da 0.502: `set`
   recusando chave desconhecida/página inexistente sem tocar `config.json`,
   `vtnc help` listando os sete namespaces, e o service do relógio ligando
   ao primeiro widget visível e desligando ao último, compartilhado entre
   duas islands com styles diferentes.

   Cuidado observado aqui: o Hyprland aninhado sempre reporta **três**
   monitores, não dois — além dos dois `HEADLESS-*` que `nested.sh` declara,
   a própria janela do aninhado conta como uma tela (`WAYLAND-1`), e toda
   island mirra em todas as telas (decisão 1c.4). Contagem de `holders`
   esperada é `telas × widgets`, não `widgets` sozinho — o teste lê
   `hyprctl monitors -j` para não fixar esse número na marra.
4. **`visual/render-check.sh`** — renderiza uma page para PNG, para ser
   **olhada**, não comparada pixel a pixel. Sobe o aninhado sozinho, a menos
   que `NESTED_PID` já esteja no ambiente. Desde a 0.502, a page renderizada
   traz os dois styles do `vtnc.clock` (`digital` e `compact`) lado a lado
   com o `vtnc.square` da 0.501.

A camada 4 **precisa de compositor**: sob `QT_QPA_PLATFORM=offscreen` o
`grabToImage` nunca chama o callback de volta, com qualquer combinação de
`QT_QUICK_BACKEND` e `QSG_RENDER_LOOP`. Dentro do aninhado ele responde na
hora. Só as camadas 1 e 2 dispensam compositor.

Nenhuma delas precisa de permissão nem da tela do Theo.
