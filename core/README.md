# core

A base que não conhece ninguém acima dela: nenhum arquivo aqui importa
`island/`, `page/` ou `widgets/`.

- `grid.mjs` — matemática pura (célula base × fator do monitor, âncora +
  deslocamento → geometria em pixels). Testada em node (`tests/unit/`).
- `config-shape.mjs` — defaults e lookups sobre o documento de config. Pura,
  sem I/O, também testada em node.
- `Paths.qml` — onde o config/estado do vtnc vivem (`~/.config/vtnc`,
  `~/.local/state/vtnc`), com override por `VTNC_CONFIG_DIR`/`VTNC_STATE_DIR`
  para o ambiente de teste descartável.
- `Config.qml` — lê `config.json` com `FileView`/`watchChanges`, para captar
  um `set` da CLI sem round-trip de IPC.
- `IslandState.qml` — só em memória: a pilha de pages que um `call` empilha
  por cima da idle de cada island (até 5, decisão 1e.2), e qual page cada
  espelho está de fato desenhando (0.506, para o critério 3 — observável
  por `vtnc island <nome> get`'s `mirrors`, sem olhar pixel). Nunca grava em
  disco; é isso que faz `call` ser momentâneo e `set` permanente. A pilha e
  o desempilhar (`end`) são `ConfigShape.pushCall`/`popCall`/`topOfCall`,
  puros e testados em node — este arquivo só guarda o estado reativo por
  cima.
- `CliRunner.qml` — a única porta para o binário `cli/vtnc` de verdade
  (`Quickshell.shellDir` acha onde ele mora). A Settings usa isto para toda
  mudança (decisão 6.3): nunca escreve em `Config` nem no arquivo
  diretamente.
- `HoverCursor.qml` (0.505) — pergunta a posição do mouse a `hyprctl
  cursorpos` de tempos em tempos (só leitura — ver `island/README.md`'s
  seção de autohide para o motivo de não dar para fazer isso com uma
  superfície de verdade).
- `HyprlandSync.qml` (0.507) — fica de olho na seção `hyprland` da config e,
  quando ela muda **e** o consentimento foi dado (decisão 10.3b), dispara
  `vtnc hyprland generate`. É isto que quer dizer "a shell roda `hyprctl
  reload` sozinha" (decisão 7.2): quem dispara é a shell em execução, nunca
  o `vtnc hyprland set`, que só escreve o `config.json` como todo `set`
  (decisão 4b.4). Compara `JSON.stringify` da seção, não a config inteira,
  para não re-gerar quando o que mudou foi uma island; e como a assinatura
  começa vazia, uma shell recém-aberta re-sincroniza por conta própria se o
  consentimento já tinha sido dado antes.
- `widget-catalog.mjs` (0.508) — a lista dos modules que o editor de Pages
  **oferece** para acrescentar, pura e testada em node. Mora aqui, e nao no
  QML, para que o editor e o `page/Page.qml` nao possam discordar: um teste
  le o `Page.qml` e falha se um module do catalogo nao tiver `case` la. Nao e
  o catalogo automatico por `meta.js` que a 3b/4.x pede, com extensao de
  terceiro se apresentando sozinha — esse e outro passo. Os widgets da
  propria Settings ficam em `SETTINGS_ONLY_MODULES`: sao desenhaveis (decisao
  8.3), mas oferecer um island-editor para colocar numa page qualquer seria
  oferecer uma tela de configuracao solta.
- `widget-registry.mjs` (0.509) — quem e quem entre modules e faces, lido
  pelo node nos testes e pelo QML na shell. Importa os `meta.js` de cada
  module e de cada face, que ate a 0.508 nao eram abertos por codigo nenhum.
  A lista de faces de um module nao mora aqui nem no meta do module: ela e
  **derivada** do `module` que cada face declara (decisao 3.5), que era a
  unica forma de ela nao existir escrita em dois lugares que podem
  discordar. Tambem e daqui que sai o caminho do QML de uma face, com queda
  para o `defaultFace` do module quando o nome pedido nao existe — a config
  e um arquivo que o usuario edita a mao, e um nome errado nao pode fazer o
  widget sumir da tela.

  Medido antes de escrever, com `qml6`: **um `.mjs` consegue importar outro
  `.mjs` (ou `.js`) de outra pasta de dentro do QML**. Era a duvida que
  decidia se o meta podia morar junto de cada face ou teria de virar lista
  central. Os imports aqui ainda sao escritos a mao, um a um; o catalogo
  automatico por varredura (3b/4.x) e outro passo, e quando vier troca so
  estas linhas, porque todo o resto ja pergunta ao registro.
- `face-schema.mjs` (0.510) — o que uma face pode declarar como opcao, e
  o que a shell aceita como valor. A decisao 3.4d da a forma ao arquivo
  inteiro: a face DESCREVE, a shell DECIDE. Por isso `min`/`max`, a lista
  do `choice`, os papeis de cor e o teto do texto sao impostos aqui, de
  fora, e por isso uma declaracao ruim e DESCARTADA (`partitionSchema`) em
  vez de derrubar a face inteiro — a shell tem de ser modulavel e
  confiavel ao mesmo tempo, e um meta mal escrito de terceiro nao pode
  tirar tudo do ar. `resolveOptions` entrega so o que a face declarou, com
  o default no lugar de qualquer valor que nao sirva mais; `withOption` e
  `storedOptionsFor` guardam por nome de face, que e o que faz a 4.4
  funcionar sem codigo nenhum "lembrando" das opcoes antigas.
- `palette.mjs` (0.510) — papel de cor em cor de verdade, **provisorio**
  (decisao 3.4c) ate o bloco de Appearance existir. Nenhuma face conhece
  estes valores: a cor ja chega resolvida a ele. Trocar esta tabela troca a
  shell inteira de uma vez, que e exatamente o motivo de o controle ser
  `role` e nao um seletor de cor livre.
- `hyprland-lua.mjs` (0.507) — a geração do texto Lua, pura, sem I/O (quem
  escreve e recarrega é `cli/lib/hyprland-write.js`). Fica separada do
  `config-shape.mjs` porque trata da sintaxe do Hyprland, não da forma do
  documento de config. As teclas saem em `[[...]]` (string de colchete longo
  do Lua) porque uma tecla ou comando digitado pelo usuário pode conter
  aspas ou contrabarra; isso só quebra se o texto contiver `]]`, contra o
  que nada aqui protege.

Os tipos QML daqui são expostos via `qmldir` (singletons), não por import de
arquivo único — ver nota em `../AGENTS.md`-adjacente: imports de arquivo
único com `as` não funcionam de forma confiável neste Quickshell.
