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

**`cli/lifecycle.sh`** (0.506, do coordenador) cobre os critérios 1, 2, 3 e
5 contra uma shell viva: a gramática velha (`island <nome> call`) recusada
com um erro que diz para onde ela foi, a pilha de cinco com a mais antiga
caindo fora e o desempilhar pousando na idle, o `popupTimeout` sumindo
sozinho, o `lock` não sumindo, e — a afirmação nova do passo — qual page
cada **espelho** está vestindo, lido do campo `mirrors` que o
`island <nome> get` ganhou justamente para isso. Falsificado tirando o
`&& isFocusedMonitor` do `showingCalled`: o espelho do outro monitor passa a
mostrar a page chamada e o teste acusa.

Uma asserção dele merece nota, porque as duas óbvias não bastavam: medir os
espelhos **logo depois** do call dá a mesma resposta tanto na leitura "foco
gravado no instante do call" quanto na "foco ao vivo". O que separa as duas é
**trocar o foco de monitor depois** e conferir que a page chamada não vai
junto (decisão 1e.3b). Falsificado voltando os quatro arquivos de código ao
commit anterior: a page migra, e só essas duas asserções acusam.

O critério 4 não está aqui de propósito: provar Esc exige teclar de verdade,
e não há injeção de input escopada a um compositor nesta máquina. Ele vive em
`tools/manual/lifecycle.sh`.

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

**Correção, antes de fechar o passo**: a primeira entrega comparava o
monitor em foco ao vivo para decidir qual espelho veste a page chamada —
o coordenador mediu, e mudar o foco com uma call aberta arrastava a page
junto. Decisão 1e.3b fechou isso: o monitor é gravado uma vez, no instante
do `call` (`core/IslandState.call`'s terceiro argumento), nunca mais
comparado ao vivo. E o clique-fora saiu do contrato por inteiro (decisão
1e.4b) — meio comportamento (só cobre clicar numa janela de verdade) foi
julgado pior que nenhum. `tests/cli/lifecycle.sh`, do coordenador, não
precisou de nenhuma mudança: seu fluxo nunca troca o foco depois do
`call`, então as duas leituras do critério 3 davam o mesmo resultado nele.

**`tests/unit/lifecycle.test.mjs`** (0.506) cobre a parte pura e testável
em node sem compositor nenhum: `pageLifecycle`/`pageNeedsKeyboard`/
`pagePopupTimeout` (os defaults de uma page que não declara nada) e
`pushCall`/`popCall`/`topOfCall` — o limite de 5, a ordem de desempilhar,
o pouso na idle (`null` agora, não mais string vazia — `topOfCall` devolve
a entrada `{ page, monitor }` inteira, decisão 1e.3b) quando a pilha
esvazia. Rodado, 50/50 com o resto da suíte.

**`tools/manual/lifecycle.sh`** (0.506, novo) é para o Theo olhar, não para
rodar sozinho: Esc com e sem `needsKeyboard` (a diferença entre OnDemand e
Exclusive), popup por tempo e pelo ×, lock não saindo sozinha, e uma prova
automática (não só para olhar) de que a page chamada não migra de monitor
quando o foco muda (decisão 1e.3b) — só roda de verdade com dois monitores
conectados, com um só ela avisa e pula. Não tem mais passo de clique fora:
a decisão 1e.4b tirou o mecanismo do contrato depois que o coordenador
mediu a primeira versão deste passo seguindo o foco ao vivo em vez de ficar
fixa onde foi chamada — ver `island/README.md` para o raciocínio inteiro
por trás das duas correções.

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

## 0.507 — os keybinds do Hyprland

`tests/cli/hyprland-keybinds.sh` é a camada 3 deste passo, e `hyprctl binds
-j` é a medida exata dele, do mesmo jeito que o `reserved` do `monitors -j`
foi o da 0.504: lista as teclas que o compositor **de fato** registrou, com
`modmask` (64 é SUPER) e `key`. O `arg` do dispatcher vem como **número**,
não como o texto do comando, então este teste afirma tecla e modificador —
o conteúdo do comando se confere lendo o arquivo gerado, não os binds.

Ele é o primeiro teste que faz a shell escrever **fora** da pasta de
configuração dela e rodar `hyprctl reload` depois, que é o risco
`gerar-arquivo-no-hypr-real`. A guarda é a mesma forma do trap da 0.505: a
flag `safe` só vira 1 depois da prova, e nada que escreva roda sem ela. E a
prova **não olha a variável de ambiente** — ela pergunta ao próprio
`cli/lib/hyprland-paths.js`, com o ambiente que a shell vai receber, para
onde o caminho resolve, e recusa se não for a pasta descartável ou se for
igual ao real. Conferir `XDG_CONFIG_HOME` não provaria nada: o que importa é
o caminho resolvido.

`tools/headless/nested.sh` ganhou `NESTED_HYPR_CONFIG` para isto. A config
padrão do aninhado não declara bind nenhum nem faz `require` do arquivo do
vtnc, e os dois são o objeto deste passo — uma config própria resolve sem
mexer no que os outros testes usam. Quem passa uma config por ali é
responsável pelas próprias regras de monitor.

Quatro coisas foram medidas no aninhado antes de escrever o teste, porque o
wiki do Hyprland segue devolvendo 404 nas páginas de dispatchers e a fonte
confiável é o binário (`strings /usr/bin/Hyprland`):

- **`hl.unbind` existe** como função global do 0.57 e aceita a tecla como
  string. Ele não aparece num `grep 'hl\.'` do binário porque a mensagem de
  erro dele é `unbind: bad argument 1`, sem o prefixo — o nome está no
  cluster de strings registrado na tabela `hl`, junto de `define_submap`,
  `exec_cmd` e `is_key_down`. Desvincular uma tecla que nunca esteve
  vinculada é inócuo.
- **`require` resolve a partir da pasta da config** (`require("vtnc/
  keybinds")` acha `<config>/hypr/vtnc/keybinds.lua`) e **não fica em cache
  entre `reload`s** — se ficasse, mudar um keybind não surtiria efeito e o
  critério 5 cairia. O teste afirma isso explicitamente no último check.
- **um erro de Lua aborta dali para baixo, e só.** Tudo o que já tinha sido
  aplicado continua valendo: com um `require` nu que falha, os binds
  declarados acima dele sobrevivem e o que vem abaixo não chega a rodar. O
  modo de emergência — aquele em que sobram só `SUPER+Q`, `SUPER+R` e
  `SUPER+M` — só aparece quando o erro acontece **antes de qualquer bind ter
  sido registrado**. Medidos os dois casos. É por isso que a linha do vtnc
  vai no **fim** do `hyprland.lua`, depois da config do próprio usuário: aí
  uma falha do vtnc não pode custar um atalho dele nem levá-lo à emergência.
  O `pcall` deixa de ser proteção contra catástrofe e vira só silêncio para
  o caso de o arquivo ainda não existir.
- **`require("vtnc")` resolve `vtnc/init.lua`** (regra padrão do Lua, que o
  Hyprland mantém), e o que vem depois de um require bem-sucedido segue
  executando. É isso que deixa o usuário nomear um ponto de entrada só, uma
  vez, e o vtnc acrescentar arquivos atrás dele depois (decisão 7.6).

Precisa de compositor, não precisa de permissão nem da tela do Theo, e em
nenhum momento toca o `~/.config/hypr` de verdade.

## 0.508 — o editor de Pages

`tests/cli/pages-editor.sh` e a camada 3. Duas coisas se medem ali que nao
dao para medir em node:

- **a decisao 6.1**, duas islands vestindo a mesma page mudando juntas. Para
  isso o `island <nome> get` ganhou `widgetCount` e `empty`, pelo mesmo
  motivo que ganhou `mirrors` na 0.506: um campo que existe para tornar a
  decisao observavel de fora sem olhar um pixel. `widgetCount` e contado
  pela **shell**, a partir da page que a island veste agora, entao ele so
  muda se a shell de fato enxergou a mudanca.
- **o estado empty da 14.3 chegando ao compositor**. A bolinha nao e so
  desenho: ela encolhe o retangulo da island, e portanto a reserva. O teste
  le o `reserved` do `monitors -j` antes e depois de apagar a page e exige
  32 px (4 celulas) virando 16 px (2 celulas).

Na camada 1, `tests/unit/page-editing.test.mjs` tem um teste que vale
apontar: ele **le o `page/Page.qml`** e falha se um type do catalogo nao
tiver `case` la, e tambem se um widget da propria Settings aparecer no
catalogo. Os dois erros seriam silenciosos de outro jeito — o primeiro da um
widget que o editor oferece e a page desenha em branco.

`tests/cli/settings-pages-click-path.sh` e o critério 5. Ele sozinho nao
prova muita coisa: se o widget escrevesse a configuracao por conta propria,
passaria igual. Quem prova a fronteira e o `settings-write-boundary.sh`, que
deixa o `cli/vtnc` sem permissao de execucao e exige que o `config.json`
fique intacto. Os dois andam juntos.

Foi esse click-path que pegou um defeito real: o editor escolhia a page
aberta no `Component.onCompleted`, que corre antes de o `Config` ter lido o
arquivo, e o editor ficava preso no vazio para sempre. Virou ligacao, que
esta sempre certa e ainda resolve de graca o caso de a page aberta ser
apagada.


## 0.509 — a interface que o type publica

A camada 1 e onde este passo tem dentes. `tests/unit/widget-registry.test.mjs`
le o QML de cada style, pega as `required property` da raiz e reprova se
alguma nao estiver publicada no `provides` do meta do type (decisao 3.5b).
Falsificado na marra: acrescentei uma `required property string inventado`
ao `Digital.qml` e o teste acusou pelo nome, dizendo qual style exigia o
que. Sem ele, `provides` seria mais um comentario que envelhece — basta
alguem acrescentar uma propriedade e passar a entrega-la na mao.

O mesmo arquivo confere o registro contra o **disco**: toda pasta de widget
esta registrada, os styles de um type sao exatamente as pastas em
`styles/`, e todo `component` nomeado por um meta existe. E ha um teste que
impede a regressao estrutural: nenhum QML de type pode voltar a escolher
style com `case "<nome>":`, porque quem sabe isso e o registro.

Esses testes pegaram uma inconsistencia que ja estava la: o meta do style
`panel` do `pages-editor` nao declarava a que type pertencia, e carregava um
`options: {}` que nada lia. Ninguem notaria enquanto os metas fossem
decoracao.

`tests/cli/style-switch.sh` e a camada 3, sete medidas. O que so se mede ali
e que a shell **resolve** o style pelo registro em vez de repetir o que esta
no `config.json`: uma instancia sem `style` tem de aparecer vestindo o
`defaultStyle` do type. Para isso o `island <nome> get` ganhou `widgets`,
com o `type` e o `style` de cada instancia — mesmo motivo do `mirrors` na
0.506 e do `widgetCount` na 0.508. O teste tambem exige que um style
inexistente na config nao faca o widget sumir.

`tests/cli/settings-style-click-path.sh` e o critério 4, no molde dos
outros click-paths. O chip de style e o mais frágil de achar que temos: o
rótulo é o **título** do style, que vem do meta pelo registro, e não um
texto escrito no painel — se o registro deixar de ser lido, o chip não
existe e o teste reprova por não encontrá-lo.
