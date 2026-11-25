# cli

`vtnc <namespace> <nome> <verbo> [args...]` — a gramática da decisão 4b.2.
Para verbos sem alvo (`list`), a forma é `vtnc <namespace> <verbo> [args...]`.

- `set` escreve direto em `config.json` (decisão 4b.4), sem precisar da shell
  rodando — `core/Config.qml` capta a mudança ao vivo via `FileView`.
- `call`, `get` e `list` falam com a shell em execução pela IPC nativa do
  Quickshell (`qs ipc call`), registrada em `shell.qml` via `IpcHandler`.
  Por isso precisam da shell de pé.

`vtnc` sem argumentos inicia a shell (`qs -p <esta pasta>`). A pasta-mãe do
`cli/` dobra como a raiz da config do Quickshell, então a CLI nunca precisa
ser avisada se está falando com `vtnc-dev` ou `vtnc`.

Os sete namespaces de topo da decisão 4b.3 todos aparecem em `vtnc help`;
hoje só `island`, `page` e `service` têm verbo — os outros (`widget`,
`monitor`, `preset`, `theme`) existem só para a lista não ficar incompleta
depois.

`set` em island valida antes de escrever: chave desconhecida ou valor que
aponta para algo que não existe (uma page inexistente, uma camada que não é
`background`/`bottom`/`top`/`overlay`) é recusado com erro e `config.json`
fica como estava — nunca escreve um config que a própria shell não
conseguiria ler de volta (o princípio por trás da decisão 5.4, aplicada
aqui ao `set`, não só ao Settings).

As chaves aceitas por `set` em island são uma lista fechada (decisão
0.502i): `page`, `layer`, e — desde a 0.503, para a página Islands da
Settings — `anchor`, `offset` e `size`. As três últimas são objetos, não
escalares, então chegam como um único argumento JSON
(`set anchor '{"top":true,"left":true}'`); `core/config-shape.mjs` faz o
parse e valida o formato antes de qualquer coisa chegar perto do arquivo.

Desde a 0.504, `gap` entrou na mesma lista: um número inteiro só, nunca
quatro lados (decisão 2d.3) — `vtnc island bar set gap 2`. É o gap exclusivo
que soma ao retângulo da island na hora de pedir a reserva de espaço ao
Hyprland; ver `island/README.md` para a conta.

Desde a 0.505, `autohide` (booleano) e `autohideMode` (`always`/`window`/
`fullscreen`) também entraram na lista — `vtnc island bar set autohide true`,
`vtnc island bar set autohideMode window`. Os dois são sobrescritas
opcionais: ausentes, a island usa o valor global.

Desde a 0.506, o gatilho mora na page, não na island (decisão 1b.5):
`vtnc island <nome> call` não existe mais — a CLI recusa com uma mensagem
dizendo para onde foi, em vez de falhar na IPC sem explicação. A forma
certa é `vtnc page <nome> call <island>`, que empilha `<nome>` por cima da
idle do `<island>` (até 5 de fundo, decisão 1e.2). Desempilhar é por
island, não por page — `vtnc island <nome> end` tira um nível (volta à
anterior, ou à idle quando a pilha esvazia); é o mesmo verbo que Esc,
clique-fora, o × do popup e o tempo do popup chamam por baixo
(`core/IslandState.end`, ver `island/README.md`).

O namespace `autohide` (0.505) é global, sem nome de alvo — a mesma gramática
de `page list`/`service list`: `vtnc autohide set <chave> <valor>` aceita
`enabled`, `mode` e `distance` (decisão 12.4: a distância de gatilho é
global, nunca por island — é ela que decide qual das duas animações do
autohide uma island recebe, ver `island/README.md`); `vtnc autohide list`
devolve o objeto global inteiro. `fade`, `slideSpeed` e `shrinkSize` também
moram em `config.autohide`, mas não ganharam verbo aqui nem controle na
Settings nesta etapa — só o que o passo pediu explicitamente
(`autohide`/`autohideMode`/distância) entrou na CLI; os três ficam editáveis
só à mão no `config.json` por enquanto.

## O namespace `hyprland` (0.507)

Global, sem nome de alvo, igual ao `autohide`. `vtnc hyprland set <chave>
<valor>` aceita duas chaves:

- `enabled` — **o consentimento** (decisão 10.3b). Falso por omissão.
  Enquanto for falso, **nada** é escrito sob `~/.config/hypr/vtnc`, não
  importa o que `keybinds` tenha: a Settings continua editando a lista à
  vontade e o `config.json` recebe tudo; só a geração é que está trancada.
- `keybinds` — a lista inteira de uma vez, num só argumento JSON (do mesmo
  jeito que `anchor`/`offset`/`size` viajam para o `island set`). Cada
  entrada é `{ key, commands, enabled, description }` (decisão 7.5), onde
  `commands` é uma **lista** e o `enabled` de dentro é o liga/desliga
  daquele atalho — não tem relação com o consentimento global acima.

`vtnc hyprland list` devolve o objeto global. `vtnc hyprland generate`
escreve `~/.config/hypr/vtnc/keybinds.lua` e roda `hyprctl reload`; é o
único verbo da CLI que faz isso, e é ele que `core/HyprlandSync.qml` dispara
da shell em execução a cada mudança. Chamar à mão é inócuo e sempre
permitido — sem consentimento ele não faz nada e diz por quê.

### A linha que o usuário tem de colar

O vtnc é dono apenas da própria pasta (decisões 7.2/10.3b), então ele
**nunca** edita o `hyprland.lua` de ninguém. Quem liga o arquivo gerado à
config do Hyprland é o usuário, uma vez só:

```lua
pcall(require, "vtnc")
```

Ela nomeia o **`init.lua`** do vtnc, não um arquivo específico: é o vtnc que
decide, lá dentro, quais partes puxar. Quando um passo futuro gerar regras de
janela ou de layer, elas entram atrás desse init e o usuário **não reedita o
`hyprland.lua` de novo**. O `require` do Hyprland resolve a partir da pasta
da config (`require("vtnc")` acha `<config>/hypr/vtnc/init.lua`) e **não**
fica em cache entre `hyprctl reload`s — mudar um keybind surte efeito na
hora. A página Keybinds mostra essa linha, porque sem ela tudo parece ter
funcionado e nenhum atalho vincula.

**A linha vai no fim do `hyprland.lua`, depois da configuração do próprio
usuário.** O Hyprland aplica a config em série, e um erro de Lua aborta dali
para baixo preservando tudo o que já foi aplicado: com a linha no fim, uma
falha do vtnc nunca custa um atalho do usuário. O modo de emergência — aquele
em que sobram só `SUPER+Q`, `SUPER+R` e `SUPER+M` — só aparece quando o erro
acontece **antes de qualquer bind ter sido registrado**, que é precisamente o
que a posição no fim impede. Os dois casos estão medidos; ver
`tests/README.md`. O `pcall`, então, não é proteção contra catástrofe: é só
para o Hyprland não reclamar de um arquivo ausente enquanto o consentimento
estiver desligado.

### O unbind

O arquivo gerado desvincula, antes de vincular, **somente** as teclas que
aparecem na lista do vtnc (decisão 7.4) — a tecla que o usuário vinculou por
conta própria, em qualquer lugar fora da pasta do vtnc, nunca é nomeada ali,
logo nunca é tocada. O unbind vem primeiro por dois motivos: desligar um
atalho de fato o tira do compositor em vez de deixar um bind velho do
`reload` anterior, e uma tecla reaproveitada não termina vinculada duas
vezes. Desvincular uma tecla que não estava vinculada é inócuo.

## O namespace `page` ganha verbos (0.508)

Ate a 0.507 o `page` so tinha `call`, `get` e `list`. Agora tem tambem:

- `vtnc page <nome> create` — uma page vazia, com a grade padrao. Recusa se
  ja existir, em vez de apagar a que estava la.
- `vtnc page <nome> delete` — apaga a page. Devolve `{"deleted": ...,
  "nowEmpty": [...]}` dizendo **quais islands ficaram sem ela**.
- `vtnc page <nome> set grid '{"cols":12,"rows":6}'`
- `vtnc page <nome> set widgets '[{"module":"vtnc.clock","cell":{"x":0,"y":0,"w":6,"h":2}}]'`

As duas chaves viajam como um argumento JSON so, do mesmo jeito que
`anchor`/`offset`/`size` do island e `keybinds` do hyprland. `widgets`
substitui a lista inteira: a page e **dona** das instancias (decisao 6.1),
entao trocar a lista e a operacao natural, e mexer numa page muda **todas**
as islands que a usam, ao vivo. Isso e intencional, nao efeito colateral.

Uma celula precisa dos quatro numeros inteiros (`x`/`y` a partir de 0,
`w`/`h` a partir de 1) e o validador recusa o resto antes de encostar no
`config.json`: sem `w`/`h` o widget nasceria invisivel e sem `x`/`y`
empilharia no canto — os dois parecem "o botao nao fez nada" para quem esta
usando.

`create` e `delete` so existem neste namespace, do mesmo jeito que
`generate` so existe no `hyprland`; nos outros a CLI recusa dizendo isso, em
vez de deixar a chamada morrer dentro da IPC.

### Apagar uma page em uso

`delete` **nao mexe nas islands** de proposito. Elas continuam apontando
para um nome que nao existe mais, e quem desenha o estado empty nesse caso e
a shell (decisao 14.3): a island vira uma bolinha de 2x2 celulas. Mexer nas
islands aqui faria a CLI reescrever configuracao que o usuario nao pediu
para mudar, e ainda perderia o nome que ele tinha escolhido. A bolinha serve
tambem para a island recem-criada que ainda nao veste nada.

A reserva de espaco encolhe junto com a bolinha, porque as duas saem do
mesmo retangulo (`Grid.emptyStateIsland`): uma island vazia que seguisse
reservando quarenta celulas empurraria as janelas do usuario por nada, e ele
nao teria como ver o porque.


## Trocar a face de um widget (0.509)

Nao ha verbo novo. A face de uma instancia e um campo dela, entao trocar o
face e reescrever a lista da page, do mesmo jeito que mover um widget:

```sh
vtnc page dash set widgets '[{"module":"vtnc.clock","face":"compact","cell":{"x":0,"y":0,"w":6,"h":2}}]'
```

`face` continua **opcional**: sem ele a instancia veste o `defaultFace`
declarado no meta do module (ver `../modules/README.md`). Um nome que nao
existe naquele module tambem nao quebra nada — a shell cai no padrao em vez de
deixar o widget sumir, porque o `config.json` e um arquivo que o usuario
edita a mao.

O `vtnc island <nome> get` passou a devolver `widgets`, com o `module` e o
`face` de cada instancia **como a shell os resolveu** — nao como o
`config.json` os escreveu. E o que torna a troca observavel de fora sem
olhar um pixel, pelo mesmo motivo que `mirrors` (0.506) e `widgetCount`
(0.508) existem.

## As opcoes de face (0.510)

Tambem nao ha verbo novo: as opcoes sao campo da instancia, entao viajam
dentro do `page <nome> set widgets`, guardadas **por nome de face**
(decisao 4.4):

```sh
vtnc page dash set widgets '[{"module":"vtnc.clock","face":"digital",
  "cell":{"x":0,"y":0,"w":6,"h":2},
  "options":{"digital":{"fontSize":32},"compact":{"showSeconds":true}}}]'
```

O validador recusa, com o motivo, o que a face nao pediu — numero fora do
`min`/`max`, escolha fora da lista, papel de cor que nao existe, texto
acima do teto (decisao 3.4d: quem decide e a shell, nao a face):

```
invalid widgets: option "fontSize" of face "digital" on vtnc.clock: precisa estar entre 8 e 72
```

Duas coisas ele **nao** recusa, de proposito: opcoes guardadas debaixo de
uma face que nao existe mais, e uma chave que a face deixou de declarar.
As duas sao a memoria da 4.4 — recusa-las faria "trocar de face e voltar"
perder tudo. O que elas nao fazem e chegar à face, que so recebe o que
declarou.

O `vtnc island <nome> get` devolve, em cada widget, as `options` **como a
shell as resolveu**: o guardado quando serve, o default declarado quando
nao. Os papeis de cor saem pelo nome, nao ja virados cor — a tabela de
cores e provisoria (3.4c) e nenhum teste deve depender dela.
