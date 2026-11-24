// Descreve o type (decisao 19.1). Desde a 0.509 este arquivo e lido de
// verdade por core/widget-registry.mjs, no node e no QML: ele nao e mais
// comentario ao lado do codigo.
//
// `styles` nao mora mais aqui. Quem diz que um style pertence a este type e
// o meta do proprio style (decisao 3.5), e o registro agrupa por ali — era
// a unica forma de a lista nao ficar escrita em dois lugares que podem
// discordar. O que fica aqui e `defaultStyle`: um nome so, usado quando a
// instancia do widget nao escolheu nenhum.
//
// `provides` e a decisao 3.5b: como terceiros escrevem styles para types do
// vtnc, o type precisa documentar e manter estavel o que entrega a eles.
// Um teste le o QML de cada style e reprova se ele exigir algo que nao
// esteja nesta lista.
export default {
    type: "vtnc.clock",
    title: "Clock",
    services: ["clock"],
    defaultStyle: "digital",
    provides: [
        { name: "time", kind: "string", doc: "A hora corrente formatada pelo service clock, HH:MM:SS." },
    ],
};
