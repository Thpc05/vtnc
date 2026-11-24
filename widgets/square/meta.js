// O type mais burro que existe, de proposito: ele prova a separacao
// type/style (3.1/3.5) com o minimo de codigo. Ver widgets/clock/meta.js
// para o que cada campo quer dizer.
export default {
    type: "vtnc.square",
    title: "Square",
    services: [],
    defaultStyle: "default",
    provides: [
        { name: "text", kind: "string", doc: "O texto a desenhar dentro do quadrado; vem da propria instancia do widget." },
    ],
};
