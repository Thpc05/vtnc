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

   Outra pegadinha notada na 0.503: o `shell.qml` para no primeiro filho que
   falha (hoje, `IslandManager`, por causa do PanelWindow). Um irmão
   declarado **depois** dele (como `Settings {}`) só é checado se também for
   alcançado por um import de algo que JÁ está na cadeia que falha — no caso
   da 0.503, `page/Page.qml` importa `widgets/island-editor` incondicionalmente
   (não só dentro do `switch`), e é isso que garante que o tipo seja
   verificado mesmo sem a Settings chegar a instanciar. Sem essa importação
   cruzada, um erro só na Settings passaria batido neste script. Confirmei
   isolado (reordenando `Settings {}` antes de `IslandManager {}` só para o
   teste, depois revertido) que ela compila e instancia sozinha sob
   offscreen — mas isso não é algo que este script cobre sozinho hoje.
3. **`cli/contract.sh`** — contrato da CLI contra uma shell de verdade, no
   Hyprland aninhado (`tools/headless/nested.sh`). Serve como teste de
   aceite dos seis critérios da 0.501, dos seis da 0.502, e agora de dois
   da 0.503: a Settings aparece em `hyprctl clients` e nunca em
   `hyprctl layers` (critério 1), já que ela é janela comum, não
   layer-shell (decisão 1d.6).

   Cuidado observado aqui: o Hyprland aninhado sempre reporta **três**
   monitores, não dois — além dos dois `HEADLESS-*` que `nested.sh` declara,
   a própria janela do aninhado conta como uma tela (`WAYLAND-1`), e toda
   island mirra em todas as telas (decisão 1c.4). Contagem de `holders`
   esperada é `telas × widgets`, não `widgets` sozinho — o teste lê
   `hyprctl monitors -j` para não fixar esse número na marra.
3b. **`cli/settings-write-boundary.sh`** — o critério 4 da 0.503: chama as
   funções reais de `vtnc.island-editor` (as mesmas que um clique no
   `Panel` chamaria) e confere que a mudança chega em `config.json` com
   `cli/vtnc` executável, e **não** chega com `cli/vtnc` tornado
   inexecutável. Não precisa de compositor — `vtnc.island-editor` é um
   `Item` comum, e `core/CliRunner.qml` só precisa de
   `Quickshell.shellDir`, que `qs -p` dá sem backend Wayland nenhum.

   Pegadinha de `Quickshell.shellDir`: ele é "o diretório de onde este
   arquivo rodou", não "onde a `vtnc-dev` mora" — e a resolução de import
   via `qmldir` só enxerga a árvore abaixo desse diretório, nunca um `../`
   que suba para fora dela. Por isso o harness (`settings-write-boundary.qml`,
   que mora em `tests/cli/` com um import relativo correto dali) é copiado
   para a raiz da `vtnc-dev` antes de rodar, com o import reescrito por
   `sed` para ficar relativo à raiz — o fonte versionado em `tests/` não
   muda, só a cópia descartável usada na hora do teste.
4. **`visual/render-check.sh`** — renderiza uma page para PNG, para ser
   **olhada**, não comparada pixel a pixel. Sobe o aninhado sozinho, a menos
   que `NESTED_PID` já esteja no ambiente. Desde a 0.502, a page renderizada
   traz os dois styles do `vtnc.clock` (`digital` e `compact`) lado a lado
   com o `vtnc.square` da 0.501.
4b. **`visual/settings-render-check.sh`** — o critério 6 da 0.503: abre a
   Settings de verdade (`settings/Settings.qml`) na página Islands e tira
   um PNG. Ao contrário de `render-check.sh`, roda via `qs -p`, não
   `qml6` puro — `Settings` depende de `core/Config.qml`, um singleton
   `pragma Singleton`, que só funciona com o runtime do Quickshell por
   trás; `qml6` sozinho carrega o arquivo mas falha em silêncio ("Did not
   load any objects") nesse caso. Mesma pegadinha de import do item acima,
   mesma solução (copia para a raiz, reescreve o import). `qs` também não
   repassa argumentos depois de `--` do jeito que `qml6` repassa, então o
   caminho de saída vai por `VTNC_RENDER_OUT` (variável de ambiente), não
   por `Qt.application.arguments`.

A camada 4 **precisa de compositor**: sob `QT_QPA_PLATFORM=offscreen` o
`grabToImage` nunca chama o callback de volta, com qualquer combinação de
`QT_QUICK_BACKEND` e `QSG_RENDER_LOOP`. Dentro do aninhado ele responde na
hora. Só as camadas 1 e 2 — e o teste de fronteira de escrita da Settings
(3b), que não depende de superfície nenhuma — dispensam compositor.

Nenhuma delas precisa de permissão nem da tela do Theo.
