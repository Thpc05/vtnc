# vtnc

Shell para Hyprland escrita em QML sobre [Quickshell](https://quickshell.org). Esta é a **0.5**,
reescrita do zero. A 0.4 está congelada na branch `0.4` e **não deve ser consultada como modelo**:
nada dela é transplantado.

Autor: Thpc (Theo). Fala-se português com ele.

## As pastas

Três repositórios **independentes** (não worktrees — eles já foram worktrees e apagar uma pasta
derrubou o git das três de uma vez), todos remotos de `github.com/Thpc05/vtnc`:

| Pasta | Branch | |
|---|---|---|
| `~/.config/quickshell/vtnc-dev` | `dev` | **onde se trabalha.** Commit livre aqui. |
| `~/.config/quickshell/vtnc` | `main` | a versão estável. Só o Theo publica nela. |
| `~/.config/quickshell/vtnc-0.4` | `0.4-dev` | a 0.4 arquivada. **Nunca edite.** |

A pasta da versão atual é sempre `vtnc`, sem número. Existe **uma só** pasta de desenvolvimento,
`vtnc-dev`, que nunca leva versão no nome e nunca é arquivada. Arquivar é renomear `vtnc` para
`vtnc-<versão>` — não existe `vtnc-0.4-dev`.

## A verdade não está neste repositório

O desenho inteiro da 0.5 — mais de 130 decisões, o vocabulário do modelo, os riscos aceitos e as
perguntas deixadas em aberto — vive num grafo **Omnigraph**, não em arquivos. Este `AGENTS.md` é só
a porta de entrada.

```sh
omnigraph query --target vtnc --format table -e 'query s() {
    match { $s: Step }
    return { $s.slug, $s.title, $s.status, $s.goal }
    order { $s.ordinal } limit 20
}'
```

Se der `connection refused`, o servidor caiu (ele não sobe sozinho no boot). Para levantar:

```sh
omnigraph-serve   # sobe só o servidor, e sai em silêncio se ele já estiver no ar
```

Nunca abra o Studio para subir o servidor: o Studio é do Theo. A dependência só vale num sentido —
o Studio sobe o servidor, o servidor nunca abre o Studio.

A fonte do grafo (a ontologia e as cargas) está versionada neste repositório, em
[`docs/graph/`](docs/graph/); o banco em si fica em `~/.local/share/omnigraph/vtnc-data/` e não vai
para o git.

**Mudar a ontologia** (`docs/graph/schema.pg`) exige parar o servidor, porque ele recusa rotas de
deploy sem autenticação:

```sh
kill $(pgrep -f 'bin/omnigraph-server')
omnigraph cluster plan  --target ~/.local/share/omnigraph/vtnc-data --config docs/graph
omnigraph cluster apply --target ~/.local/share/omnigraph/vtnc-data --config docs/graph --as thpc
omnigraph cluster force-unlock "$(omnigraph cluster status \
    --target ~/.local/share/omnigraph/vtnc-data --json | python3 -c 'import sys,json;print(json.load(sys.stdin)["lock_id"])')" \
    --target ~/.local/share/omnigraph/vtnc-data
omnigraph-serve
```

Adicionar propriedade anulável é barato; mudar uma constraint existente é reconstrução. Leia a
skill `omnigraph` antes.

### As consultas que você vai usar

Tudo que foi decidido sobre um conceito (`island`, `page`, `widget`, `module`, `face`, `service`,
`cell`, `grid`, `layer`, `lifecycle`, `cli`, `notch`, `preset`, `plugin`, `settings`, `startup`,
`animation`, `game-mode`, `density`, `exclusive-zone`, `edit-mode`, `empty-state`,
`hyprland-integration`, `dependency`, `screen-decoration`, `test-environment`, `process`,
`omnigraph`):

```sh
omnigraph query --target vtnc --format table --params '{"c":"island"}' -e 'query d($c: String) {
    match {
        $k: Concept { slug: $c }
        $d: Decision
        $d decidesAbout $k
    }
    return { $d.block, $d.title, $d.statement }
    order { $d.block } limit 60
}'
```

O que está **deliberadamente em aberto** — leia antes de começar qualquer etapa:

```sh
omnigraph query --target vtnc --format table -e 'query q() {
    match { $q: OpenQuestion { status: "open" } }
    return { $q.slug, $q.question, $q.note } limit 30
}'
```

Os riscos já aceitos (não os levante de novo, já foram discutidos):

```sh
omnigraph query --target vtnc --format table -e 'query r() {
    match { $r: Risk }
    return { $r.title, $r.statement, $r.mitigation } limit 20
}'
```

## O modelo, em um minuto

Só para você não consultar o grafo às cegas. O detalhe está lá, não aqui.

- **Island** — superfície Wayland que ocupa células do grid da tela e veste **uma page por vez**.
- **Page** — grupo **reutilizável** de widgets com grid próprio. É **dona** das instâncias de
  widget, então mexer numa page muda todas as islands que a usam. O **ciclo de vida**
  (`idle` · `called` · `popup` · `lock`) e o gatilho são dela, não da island.
- **Widget** — um **module** (a função; nomeia os services que usa) vestindo uma **face** (a
  aparência). Uma face pertence a **um único module**; um module tem várias faces. Os dois juntos
  são a **camada visual** de um **plugin**, que pode trazer também uma **camada serviço**.
- **Service** — código único e compartilhado que fala com o sistema, ligado só quando algum widget
  visível precisa e desligado quando o último sai de cena.
- **Célula** — tudo é medido em células: uma célula base global × um fator por monitor. Posição é
  **âncora + deslocamento**, nunca pixels absolutos.
- **CLI** — `vtnc <namespace> <nome> <verbo> <args>`, onde `call` é momentâneo e `set` é permanente.
  Ela é o motor: o Settings não tem lógica própria, ele chama a CLI.

## Regras de trabalho

- **Um passo por vez.** A série `0.50x` — `0.501` até `0.510` — implementou o desenho fechado nos
  19 blocos e **acabou**. Hospedar plugins é escopo novo, então estamos na série `0.51x`: `0.511`,
  `0.512`… Versões não levam pontos extras: `0.5.1.1` se escreve `0.511`, e isso vale para pastas e
  para todo lugar. Entre um passo e outro há revisão — não emende dois.
- **Pergunta em aberto não se decide sozinho.** Se o que você precisa está numa `OpenQuestion`,
  pare e pergunte ao Theo.
- **Português** na documentação; **inglês** no código e em todo texto que o usuário vê.
- **Cada pasta se descreve**: um `README` por área, um `meta.js` por widget. É isso que faz o
  catálogo automático funcionar e que deixa um plugin de terceiro se apresentar sozinho.
- **Commit** livre nesta branch, um por passo fechado. Mensagens em inglês.
- **Nunca** edite `~/.config/quickshell/vtnc-0.4` nem a branch `0.4`.
- **Hyprland**: `hyprctl reload` pode sempre. `hyprctl dispatch` e trocar de workspace estão
  **liberados para teste** — vá para um workspace vazio, faça o que precisa e volte para o do Theo.
  Abrir janelas (`kitty`) para testar zona exclusiva também pode. Fora de teste, não mexa na sessão
  dele.
- **Os dispatchers do 0.57 são Lua.** A forma antiga não existe mais:
  `hyprctl dispatch workspace 2` devolve erro de parse. Passe uma expressão Lua:

  | o que você quer | o comando |
  |---|---|
  | ir para um workspace | `hyprctl dispatch 'hl.dsp.focus({ workspace = 2 })'` |
  | focar um monitor | `hyprctl dispatch 'hl.dsp.focus({ monitor = "HEADLESS-1" })'` |
  | mover o cursor | `hyprctl dispatch 'hl.dsp.cursor.move({ x = 400, y = 7 })'` |
  | tela cheia | `hyprctl dispatch 'hl.dsp.window.fullscreen({ mode = "fullscreen" })'`, e `{ mode = 0 }` para sair |
  | fechar janela | `hl.dsp.window.close()` — mas prefira `kill $PID` da janela que você mesmo abriu |

  **O `hyprctl` imprime o erro no `stdout`, não no stderr, e devolve 7** — um `>/dev/null` engole a
  falha inteira, e com `set -e` o script morre sem dizer nada. Confira a saída, não só o código.
- Pesquise sempre no **wiki oficial do Hyprland**, na versão instalada (hoje a 0.57). Hoje ele
  devolve 404 nas páginas de dispatchers e de `hyprctl`; enquanto isso, a fonte mais confiável é o
  próprio binário: `strings /usr/bin/Hyprland | grep -E 'hl\.dsp'` traz a config padrão embutida.

## Testes

Quatro camadas, nem todas rodam em toda etapa:

1. lógica pura em JS, testada em node;
2. todo o QML compila;
3. contrato da CLI, conferido pelo JSON que ela devolve;
4. visual, renderizado em claro e escuro e **olhado** — sem comparação de pixels.

As camadas 1 e 2 dispensam compositor (`QT_QPA_PLATFORM=offscreen`). As camadas 3 e 4 rodam num
**Hyprland aninhado** dentro da sessão do Theo (`tools/headless/nested.sh`), com uma pasta de
configuração descartável. A tela real do Theo é o modo de maior fidelidade, pedido a ele a cada
vez — veja [`tools/README.md`](tools/README.md).

**Quem implementa não declara o próprio teste verificado.** A linha é esta:

- **do implementador:** os casos de teste do passo — o que ele precisa provar. Rode-os enquanto
  desenvolve, porque não dá para programar às cegas, mas entregue dizendo o que você *acredita* que
  funciona e onde está inseguro, não uma lista de OKs.
- **do coordenador:** o arranjo (`tools/headless/`, os scripts que rodam as camadas), o veredito, e
  investigar o que falhar. Não mexa no arranjo sem avisar — senão nós dois consertamos a mesma coisa.

De tempos em tempos o coordenador roda a tomada na tela real do Theo, por garantia.
