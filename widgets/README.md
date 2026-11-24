# widgets

Cada pasta aqui é um *type*: a função do widget, nomeando os services que
usa (decisão 15.2b). Um type nunca importa outro widget.

```
widgets/<type>/
    meta.js              descreve o type (decisão 19.1)
    <Type>.qml            a implementação do type
    styles/<style>/
        meta.js           descreve o style — pertence a um único type (3.5)
        <Style>.qml
```

## Os `meta.js` valem de verdade desde a 0.509

Até a 0.508 eles eram decoração: nada no código os abria. Agora
`core/widget-registry.mjs` os importa, no node e no QML, e é dele que sai
toda pergunta sobre quem é quem.

O **meta do type** declara:

| campo | |
|---|---|
| `type` | o nome completo, com o prefixo da fonte (3.1) |
| `title` | como ele aparece no catálogo |
| `services` | os services que ele consome (5.2b), nem que seja `[]` |
| `defaultStyle` | o style que a instância veste quando não escolheu nenhum |
| `provides` | **a interface que ele entrega aos styles** (3.5b) |

O **meta do style** declara `style`, o `type` a que pertence (3.5),
`title` e `component`, o arquivo QML que o type carrega.

A lista de styles de um type **não existe escrita em lugar nenhum**: ela é
derivada do `type` que cada style declara. Antes da 0.509 ela vivia em dois
lugares — no meta do type e num `switch` dentro do QML dele — com nada
obrigando os dois a concordarem. Hoje o type pede ao registro o caminho do
QML do style e carrega por `Loader.setSource`; acrescentar um style a um
type é acrescentar uma pasta com um meta, e o QML do type não muda.

Por causa do `setSource`, tudo que o type entrega ao style viaja como
`Qt.binding(() => ...)`. Um valor cru congelaria o style no primeiro quadro
— foi por isso que o relógio precisou disso primeiro.

### `provides`, e por que ele não é comentário

A decisão 3.5b existe porque **terceiros escrevem styles para types do
vtnc**: quem for fazer um style novo precisa saber o que vai receber sem
abrir o QML do type. Cada entrada é `{ name, kind, doc }`.

Um teste unitário lê o QML de cada style, pega as `required property` da
raiz e reprova se alguma não estiver publicada no meta do type. Sem ele,
`provides` envelheceria em silêncio: bastaria alguém acrescentar uma
propriedade exigida e passar a entregá-la na mão.

`options` é a única exceção, listada em `FRAMEWORK_PROPERTIES`: é o canal
que o vtnc dá a todo style, não algo que este ou aquele type inventou.

## As opções de um style (0.510)

Um style declara as suas opções no próprio meta, em `options`. A tela de
configuração é montada **a partir dessa declaração** — a Settings não
conhece style nenhum pelo nome (decisão 3.4).

A régua é a decisão 3.4d: **o style descreve, a shell decide.**

- O que o style entrega é **dado, nunca código**. Nenhuma função dele é
  chamada pela Settings, nenhum QML dele é executado por ela.
- Os controles são cinco e só cinco (3.4b): `toggle`, `number` (com
  `min`/`max`/`step` e unidade `plain`/`cell`/`px`), `choice` (lista
  fechada de `{ value, title }`), `text` e `role`.
- **Quem valida o valor é a shell**, em `core/style-schema.mjs`: o número
  fora da faixa, a escolha fora da lista, o papel de cor que não existe e o
  texto acima do teto são recusados antes de chegar ao `config.json`.
- Uma **declaração** inválida é descartada com aviso, e o resto do style
  continua carregando. Um meta mal escrito custa aquela opção, não a shell.
- `role` é cor **por papel**, nunca hexadecimal (3.4b/3.4c). O style nomeia
  `accent`; quem traduz papel em cor é `core/palette.mjs`, e o style recebe
  a cor já pronta. É isso que deixa o bloco de Appearance trocar a shell
  inteira sem tocar em style nenhum.

O valor chega ao style pelo canal `options`, já resolvido: o guardado
quando serve, o default declarado quando não. **O style nunca vê uma chave
que não declarou**, e nunca precisa se defender de um valor torto.

Na instância, as opções ficam guardadas **por nome de style**:

```json
{ "type": "vtnc.clock", "style": "digital",
  "options": { "digital": { "fontSize": 32 }, "compact": { "showSeconds": true } } }
```

É isso, e só isso, que faz a decisão 4.4 funcionar: trocar de style e
voltar não perde nada, porque as opções do style antigo continuam ali
debaixo do nome dele. Nenhum código precisa "lembrar" de nada.

## Os types que existem

- `square` (0.501) — um quadrado burro com texto, para provar o tripé
  type/style/page com o mínimo de código possível (decisão 16.4). Sem
  services — não precisa de nenhum.
- `clock` (0.502) — consome o service `clock` (`../services/clock/`) e
  tem dois styles, `digital` e `compact`, escolhidos só pela configuração
  (decisão 3.1/3.5). `acquire`/`release` do service acontecem em
  `Component.onCompleted`/`onDestruction` — o `Loader` da `Page` já destrói
  o widget sozinho quando a page troca, então o desligar do service é de
  graça, não precisa de código extra para isso.
- `island-editor` (0.503, gap em 0.504, autohide em 0.505) — o controle da
  página Islands da Settings (decisão 8.3): lê uma island direto de
  `core/Config.qml` e só escreve através de `core/CliRunner.qml`, nunca em
  `Config` (decisão 6.3). Um style só, `panel`, porque Appearance (estilo
  visual da própria Settings) está fora de escopo aqui. Desde a 0.504
  também expõe o gap exclusivo da island, pelo mesmo caminho (`set gap`);
  desde a 0.505, o `autohide`/`autohideMode` da island (resolvidos com o
  global via `ConfigShape.resolveAutohide`) — ver `island/README.md` para a
  conta por trás dos dois.
- `autohide-settings` (0.505) — o único controle global do autohide na
  página Islands: a distância de gatilho (decisão 12.4), mostrada uma vez
  só, acima de cada `island-editor`. Mesma fronteira de escrita que
  `island-editor` — lê `core/Config.qml`, escreve só via `CliRunner`
  (`autohide set distance`).
- `keybinds-editor` (0.507) — a página Keybinds da Settings inteira: o
  consentimento (decisão 10.3b) e a lista de keybinds (decisão 7.5). Mesma
  fronteira de escrita que `island-editor`/`autohide-settings` — lê
  `core/Config.qml`, escreve só via `CliRunner` (`hyprland set enabled` /
  `hyprland set keybinds`). Nunca toca `~/.config/hypr` — isso só acontece
  quando o consentimento está ligado e a shell em execução reage à mudança
  (`core/HyprlandSync.qml`, ver `cli/README.md`). Primeiro widget da
  Settings com texto livre — introduz `TextInput`, só confirmado em
  `onEditingFinished`, nunca por tecla.
- `not-built` (0.503) — o que aparece nas nove páginas da Settings que
  ainda não existem (decisão 8.1). Mesmo o placeholder é um widget de
  verdade, para a Settings inteira ficar dentro do mecanismo de pages e
  widgets, sem caso especial por fora.

- `pages-editor` (0.508) — a pagina Pages da Settings. Lista, cria e apaga
  pages; dentro da page aberta acrescenta e remove widget e mexe na celula
  de cada um. Le `core/Config.qml` e escreve so via `CliRunner`
  (`page <nome> create` / `delete` / `set grid` / `set widgets`). O que ele
  oferece para acrescentar vem de `core/widget-catalog.mjs`, nao de uma
  lista escrita aqui dentro. A page aberta e uma **ligacao**, nao estado
  montado na inicializacao: o `Config` pode ainda nao ter lido o arquivo
  quando o widget nasce.

