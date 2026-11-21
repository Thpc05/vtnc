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
3c. **`cli/exclusive-zone.sh`** — os quatro primeiros critérios da 0.504,
   contra o `reserved` de `hyprctl monitors -j`, que é a medida exata (não
   depende de interpretar o tamanho de uma janela). Quatro islands, uma por
   canto do critério 4: `bar` (faixa de borda a borda, reserva), `dock`
   (canto puro, ambíguo para o Hyprland mesmo com zona explícita — ver
   `core/grid.mjs`), `float` (sem âncora nenhuma) e `silent` (ancorada, mas
   sem page idle) — as três últimas não devem somar nada ao que `bar`
   reserva sozinha. Confirma também com uma janela de verdade (`kitty`,
   liberado para teste): ela tem de aparecer abaixo da faixa reservada, não
   por baixo dela — fácil de repetir na tela real do Theo.

   Pegadinha encontrada aqui: depois de um `set gap`, `IslandManager.qml`
   reconstrói o `Variants` inteiro de islands (o modelo é
   `config.data.islands`, e qualquer mudança no config troca a identidade
   do array inteiro) — por um instante a superfície antiga e a nova
   coexistem, e o Hyprland soma as duas zonas exclusivas. Ler
   `hyprctl monitors -j` cedo demais pegou 32+56=88px uma vez; o teste
   agora espera meio segundo depois de cada `set` antes de medir. Isto é
   uma característica de arquitetura de antes da 0.504 (o `Variants` nunca
   diferenciou by-key), não algo que este passo tenha introduzido — vale a
   pena o coordenador saber que existe, caso afete algum teste futuro mais
   sensível a tempo.

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

**`cli/settings-click-path.sh`** (do coordenador) fecha o centímetro que os
outros não alcançam: não "as funções do type chegam ao `config.json`", mas
"clicar o controle chama a função". Ele caminha a árvore de objetos até o
`MouseArea` dentro do chip `overlay` do style `panel` e emite o `clicked`
dele, então a corrente inteira roda — `MouseArea` → `Chip.activated` →
`IslandEditor.setLayer` → `CliRunner` → `cli/vtnc` → `config.json`.
Falsificado na marra: trocando o `onActivated` do chip por um `console.log`,
o teste acusa.

**`cli/settings-gap-click-path.sh`** (0.504) é o mesmo modelo aplicado ao
botão "+" do novo Stepper de gap: acha o `MouseArea` pelo texto "+" do seu
próprio filho (o `Stepper` não dá outro jeito de diferenciar de "-" por
fora — só tem `id`, que o JS não enxerga), emite o `clicked`, confere que
`config.json` ganhou um `gap` a mais. Falsificado do mesmo jeito, também
acusa.

Nada de injeção de input: `wlrctl` não está instalado e o `ydotool` passa
pelo `uinput` do kernel, que não é escopado por compositor e vazaria para a
sessão real do Theo. Se um dia um teste precisar de ponteiro de verdade,
instale um cliente do protocolo `virtual-pointer` do wlroots, que passa pelo
socket Wayland e portanto atinge só o aninhado.

A camada 4 **precisa de compositor**: sob `QT_QPA_PLATFORM=offscreen` o
`grabToImage` nunca chama o callback de volta, com qualquer combinação de
`QT_QUICK_BACKEND` e `QSG_RENDER_LOOP`. Dentro do aninhado ele responde na
hora. Só as camadas 1 e 2 — e os testes de fronteira/clique da Settings
(3b, `settings-click-path.sh`, `settings-gap-click-path.sh`), que não
dependem de superfície nenhuma — dispensam compositor. `exclusive-zone.sh`
(3c) precisa dele: mede `hyprctl monitors -j` de verdade e abre um `kitty`
de verdade.

Nenhuma delas precisa de permissão nem da tela do Theo.
