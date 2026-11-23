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

   Duas coisas que o coordenador ajustou ao verificar a 0.504. Primeira: o
   teste lia só o lado `top` do `reserved`, então uma reserva vazando para
   outra borda passaria sem ser vista — agora ele compara os quatro lados de
   uma vez (`[0, 32, 0, 0]`) e o `silent` ficou ancorado em `right`, para
   que um vazamento dele caia num lado que o `bar` não ocupa. Segunda: a
   regra de canto do `primaryExclusiveEdge` **não é observável daqui**. Quem
   a impõe é o próprio Hyprland: o protocolo `wlr-layer-shell` diz que uma
   zona positiva numa âncora de canto (ou em duas bordas opostas, ou nas
   quatro) é tratada como zero. Quebrei a regra no `grid.mjs` de propósito e
   o `reserved` não se mexeu. Quem cobre essa regra são os testes unitários,
   não este. A falsificação que este teste de fato acusa é a da page idle:
   com `hasIdlePage` forçado a `true`, ele reprova cinco das seis linhas e
   sai com 1.

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

**`cli/settings-autohide-click-path.sh`** (0.505) é o mesmo modelo aplicado
ao chip de autohide: como o rótulo do chip muda com o próprio estado
("on"/"off"), ele acha o chip pelo texto literal "off" (a fixture começa
sem sobrescrita, lendo o global — que é `off` por padrão), emite o
`clicked`, confere que `config.json` ganhou `"autohide": true` na island.
Falsificado na marra (trocando `onActivated` por um `console.log`),
também acusa — e depois restaurado, confirmado via `git diff --stat` que o
diff final só tem a mudança real do stepper, nada da falsificação.

**`cli/autohide.sh`** (0.505) é o teste de aceite dos seis critérios —
três islands, uma por modo (`always`/`window`/`fullscreen`), medindo a
reserva liberada/devolvida contra `hyprctl monitors -j`, um `kitty` de
verdade abrindo/fechando/ficando em tela cheia, e `hyprctl dispatch
movecursor` simulando o mouse chegando na borda. **Foi escrito, mas não
rodado pelo implementador** — rodá-lo, mesmo com toda chamada ao Hyprland
explicitamente escopada à instância aninhada (`HYPRLAND_INSTANCE_SIGNATURE`
reafirmado em cada `hyprctl`/`kitty`, nunca confiando num `export` herdado;
uma checagem no início recusa continuar se a assinatura aninhada vier vazia
ou igual à da sessão real), chegou a fechar/abrir janelas da sessão real do
Theo duas vezes nesta etapa, sem causa raiz confirmada. Fica para o
coordenador rodar no arranjo dele. O resto da etapa (unidade, compilação
QML, os `*-click-path.sh` acima, que não tocam em janela nenhuma) foi
rodado normalmente.

**A causa raiz foi encontrada, e eram duas.** Ambas consertadas aqui:

1. O `trap cleanup EXIT` é armado **antes** da checagem de assinatura, e
   rodava também no `exit 1` dela — momento em que `nested_sig` ainda
   guarda o que foi herdado, isto é, possivelmente a assinatura da sessão
   **real**. O `[[ -n "$nested_sig" ]]` não bastava: o cleanup então rodava
   `hyprctl dispatch closewindow class:kitty` contra a sessão do Theo, e ele
   tem exatamente duas janelas kitty. Reproduzido com um `nested.sh` falso
   que escreve um env-file vazio, com o `closewindow` trocado por um aviso:
   o caminho é alcançado. Agora existe um `nested_ok`, posto em 1 **só**
   depois da checagem passar, e nada que mexa em janela roda sem ele.
2. Se `WAYLAND_DISPLAY` chegasse vazio ao `kitty`, ele não falharia — cairia
   no XWayland (`DISPLAY=:0` existe nesta máquina) e abriria uma janela na
   sessão **real**, que nada aqui fecharia depois. O `nkitty` agora recusa.

**E o teste não rodava por um terceiro motivo, nada a ver com isso:** o
Hyprland 0.57 moveu os dispatchers para Lua. `hyprctl dispatch
movetoworkspacesilent 99,title:...` devolve erro de parse e código 7 — e
como o `hyprctl` imprime o erro no **stdout**, o `>/dev/null` engolia tudo e
o `set -e` matava o script antes da primeira asserção, sem uma linha de
saída. Ver a tabela de sintaxe no `AGENTS.md`. Toda chamada agora passa por
um `ndispatch` que falha alto, o `movetoworkspacesilent` sumiu (a shell sobe
num workspace descartável e o teste sai dele, em vez de mover a Settings
depois) e o `closewindow` virou `kill` do PID que o próprio teste abriu.

Outras duas correções de expectativa, depois que ele passou a rodar:

- `winhide` reserva **160px**, não os 80px da própria largura: o Hyprland
  **soma a margem da âncora** à zona exclusiva, e ela mora 10 células (80px)
  da borda. Troquei a altura dela de 160 para 40 para ter certeza de que não
  era a altura — a reserva não mudou. A 0.504 nunca pegou isso porque todas
  as islands que ela mediu tinham offset 0 na borda ancorada. **Se a reserva
  certa é o retângulo da island ou tudo da borda até o lado mais distante
  dela é pergunta para o Theo**, não algo que esta expectativa decide.
- A janela não começa em `y=0` e sim no gap do aninhado. O que o critério
  quer provar é que ela está **acima** da faixa de 32px que o `bar`
  reservaria — é isso que o teste afere agora.

E uma corrida no próprio teste: `ensure_fullscreen False` lia `False` logo
depois de o kitty aparecer em `clients`, **antes** de ele virar tela cheia,
voltava satisfeito, e o kitty virava tela cheia em seguida — escondendo a
island do modo `fullscreen` e reprovando o critério do modo `window` pelo
motivo errado. Agora exige duas leituras iguais, meio segundo apart.
Com isso, 10 de 10 verdes, três rodadas seguidas.

**`cli/autohide-per-monitor.sh`** (0.505, do coordenador) fecha a única
ambiguidade que sobrou da etapa: a decisão dizia "o workspace em foco", no
singular, e com vários monitores existem vários ao mesmo tempo. Três
monitores em workspaces vazios, a island visível nos três, uma janela aberta
em **um** deles — e só aquele espelho some. Repetido na tela real do Theo
com os dois monitores dele, mesmo resultado.

O arranjo é o que torna isso mensurável, e foi o Theo quem apontou: a shell
sobe num **workspace descartável**, de modo que a janela da Settings fique
lá e não conte como "existe janela" em nenhum dos workspaces que o teste
usa. Sem isso a leitura embaralha — foi exatamente o que estragou a primeira
tomada na tela real, em que a Settings nasceu no workspace medido e a island
já apareceu escondida de saída.

Nada de injeção de input: `wlrctl` não está instalado e o `ydotool` passa
pelo `uinput` do kernel, que não é escopado por compositor e vazaria para a
sessão real do Theo. Se um dia um teste precisar de ponteiro de verdade,
instale um cliente do protocolo `virtual-pointer` do wlroots, que passa pelo
socket Wayland e portanto atinge só o aninhado.

**0.506 (o ciclo de vida das pages)** moveu o gatilho da island para a page
(decisão 1b.5: `vtnc island <nome> call` virou `vtnc page <nome> call
<island>`) e deu um verbo de verdade a desempilhar (`vtnc island <nome>
end`, substituindo o `core/IslandState.clearCall` da 0.505, que nunca era
chamado por ninguém). Isso quebrou três testes já existentes de passos
anteriores — `contract.sh` (0.501/0.502), `exclusive-zone.sh` (0.504) e
`autohide.sh` (0.505) — que ainda falavam a gramática velha; os três foram
corrigidos aqui para a nova (`page <nome> call <island>` / `island <nome>
end`), já que o próprio AGENTS.md autoriza mexer num teste existente que o
passo quebrou, sem precisar de aviso.

`contract.sh` também precisou de um ajuste de expectativa, não só de
gramática: a contagem de holders do service `clock` esperava
`screen_count * 2` depois de chamar `dashboard`/`dashboard-compact` nas
duas islands — contava com toda ilha mirrando em toda tela (decisão 1c.4).
A 0.506 (decisão 1e.3) faz uma page chamada aparecer só no espelho do
monitor focado; os outros continuam na idle, que não usa o widget de
relógio. A expectativa agora é `2` (um holder por island, não um por
tela × island) — não é uma correção de teste quebrado por acaso, é o
critério novo mudando o que o critério velho media.

Nenhuma dessas três correções foi **rodada** pelo implementador — abrem
janela de verdade e/ou mandam `hyprctl dispatch` contra o aninhado, e a
regra em vigor desde o incidente da 0.505 (a sessão real do Theo foi
perturbada duas vezes rodando `autohide.sh`, mesmo escopado) é não rodar
teste de janela real por conta própria. As três foram só editadas, por
texto, para a gramática/expectativa novas — ficam para o coordenador
confirmar que ainda passam.

**`tests/unit/lifecycle.test.mjs`** (0.506) cobre a parte pura e testável
em node sem compositor nenhum: `pageLifecycle`/`pageNeedsKeyboard`/
`pagePopupTimeout` (os defaults de uma page que não declara nada) e
`pushCall`/`popCall`/`topOfCall` — o limite de 5, a ordem de desempilhar,
o pouso na idle (string vazia) quando a pilha esvazia. Rodado, 49/49 com o
resto da suíte.

**`tools/manual/lifecycle.sh`** (0.506, novo) é para o Theo olhar, não para
rodar sozinho: Esc com e sem `needsKeyboard` (a diferença entre OnDemand e
Exclusive), popup por tempo e pelo ×, lock ignorando os dois, e — o ponto
mais incerto do critério 4 — o lado de clique-fora que esta etapa consegue
construir (reage a `Quickshell.Hyprland.activeToplevel` mudar, isto é,
clicar numa janela de verdade; não clicar no desktop vazio, nem noutra
superfície do vtnc). Ver `island/README.md` para o raciocínio inteiro por
trás dessa escolha e da lacuna que ela deixa.

A camada 4 **precisa de compositor**: sob `QT_QPA_PLATFORM=offscreen` o
`grabToImage` nunca chama o callback de volta, com qualquer combinação de
`QT_QUICK_BACKEND` e `QSG_RENDER_LOOP`. Dentro do aninhado ele responde na
hora. Só as camadas 1 e 2 — e os testes de fronteira/clique da Settings
(3b, `settings-click-path.sh`, `settings-gap-click-path.sh`,
`settings-autohide-click-path.sh`), que não dependem de superfície
nenhuma — dispensam compositor. `exclusive-zone.sh` (3c) e `autohide.sh`
(0.505) precisam dele: medem `hyprctl monitors -j` de verdade e abrem
janelas de verdade — `autohide.sh` também dispara `hyprctl dispatch`
(movecursor, fullscreen, workspace), liberado só para teste (AGENTS.md).

Nenhuma delas precisa de permissão nem da tela do Theo.
