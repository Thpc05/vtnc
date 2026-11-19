# A fonte do grafo

O desenho da 0.5 vive num grafo [Omnigraph](https://github.com/ModernRelay/omnigraph). Esta pasta é
a **fonte** dele, versionada: a ontologia e as cargas que o reconstroem do zero. O banco em si fica
em `~/.local/share/omnigraph/vtnc-data/` e **não** vai para o git.

| | |
|---|---|
| `cluster.yaml` | declara o grafo `vtnc` e aponta para a ontologia |
| `schema.pg` | a ontologia: `Concept`, `Decision`, `OpenQuestion`, `Risk`, `Step` e as ligações entre eles |
| `seeds/*.jsonl` | o conteúdo, na ordem em que foi escrito |

## Reconstruir do zero

Se o banco se perder, isto o traz de volta inteiro:

```sh
DATA=~/.local/share/omnigraph/vtnc-data
omnigraph cluster apply --target "$DATA" --config . --as thpc
omnigraph cluster force-unlock "$(omnigraph cluster status --target "$DATA" --json \
    | python3 -c 'import sys,json;print(json.load(sys.stdin)["lock_id"])')" --target "$DATA"
omnigraph-serve
for f in seeds/*.jsonl; do omnigraph load --data "$f" --mode merge --target vtnc; done
```

As cargas usam `--mode merge` e as chaves são estáveis, então rodar duas vezes não duplica nada.

## Mudar a ontologia

O servidor recusa rotas de deploy sem autenticação, então **pare o servidor antes**:

```sh
kill $(pgrep -f 'bin/omnigraph-server')
omnigraph cluster plan  --target "$DATA" --config .
omnigraph cluster apply --target "$DATA" --config . --as thpc
# ... force-unlock como acima ...
omnigraph-serve
```

Acrescentar propriedade anulável aplica no lugar e é barato. Mudar ou remover uma constraint
existente é reconstrução — pense antes de prometer uma restrição.

## Escrever no grafo

Preferir `omnigraph load` com um `.jsonl` novo nesta pasta a escrever direto com `mutate`: assim o
que está no banco continua sendo exatamente o que está versionado aqui.
