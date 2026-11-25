// O manifesto de um plugin, e a validacao dele (0.512).
//
// Um plugin e uma pasta com um `plugin.json` na raiz. O manifesto diz quem
// o plugin e, contra qual nivel de API ele foi escrito, e ONDE estao as
// entradas que ele traz - uma lista de pastas, nao o conteudo delas. O
// conteudo de cada entrada fica no `meta.json` da propria pasta (decisao
// 19.1, "cada pasta se descreve"), e e o que um terceiro escreve.
//
// Por que o manifesto lista as pastas em vez de a shell varrer a arvore:
// varrer exige listar diretorio em QML, que so existe de forma assincrona
// (FolderListModel), e uma cascata assincrona dentro da carga da shell e
// bem mais fragil do que uma leitura por arquivo. Com o indice no
// manifesto a varredura e uma listagem so - a das pastas de plugin - e
// dali em diante tudo e leitura direta. O preco e o indice poder discordar
// do disco; um teste de camada 1 compara os dois e reprova a diferenca.
//
// Tudo aqui e funcao pura: o node importa este arquivo nos testes e na
// CLI, e o QML importa o mesmo arquivo na shell. Quem le disco e quem fala
// com o Qt esta em outro lugar (core/PluginRegistry.qml, cli/lib/plugins.js).

// O nivel de API e um inteiro cumulativo (decisao do Theo em 4.x, no molde
// do Noctalia): o plugin declara o nivel MAIS ANTIGO de que precisa, e a
// shell aceita de MIN ate CURRENT. Nao e semver da interface: a 5b.3 diz
// que nao existe versionamento da interface module-face, e isto nao e
// isso - e so uma faixa para a shell poder recusar com motivo em vez de
// quebrar no meio.
export const PLUGIN_API_MIN = 1;
export const PLUGIN_API_CURRENT = 1;

// Um segmento, sem ponto: o ponto separa o plugin do module
// ("vtnc.clock"), entao um id com ponto dentro tornaria o endereco
// ambiguo. A unicidade vem do banco curado pelo Theo (decisao 4.6), nao de
// um prefixo de autor - o autor e campo do manifesto.
const SEGMENT = /^[a-z][a-z0-9-]*$/;
const SEMVER = /^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$/;
const MODULE_ID = /^[a-z][a-z0-9-]*\.[a-z][a-z0-9-]*$/;

export function apiCompatible(pluginApi) {
    return Number.isInteger(pluginApi) && pluginApi >= PLUGIN_API_MIN && pluginApi <= PLUGIN_API_CURRENT;
}

// Um caminho dentro do plugin: relativo, sem subir de pasta, sem comecar
// na raiz. E a unica coisa estrutural que a shell impoe a um caminho; ela
// nao impede o QML de dentro da pasta de fazer o que quiser (4.6).
function pathProblem(value, label) {
    if (typeof value !== "string" || value.length === 0) return `${label} precisa ser um caminho`;
    if (value.startsWith("/")) return `${label} nao pode ser caminho absoluto`;
    if (value.startsWith("file:")) return `${label} nao pode ser URL`;
    const parts = value.split("/");
    if (parts.some((part) => part === "" || part === "." || part === ".."))
        return `${label} nao pode sair da pasta do plugin`;
    return null;
}

function stringList(value, label, errors, check) {
    if (value === undefined) return [];
    if (!Array.isArray(value)) {
        errors.push(`${label} precisa ser uma lista`);
        return [];
    }
    value.forEach((entry, i) => {
        const problem = check(entry, `${label}[${i}]`);
        if (problem) errors.push(problem);
    });
    return value;
}

export function validateManifest(manifest) {
    const errors = [];
    if (!manifest || typeof manifest !== "object" || Array.isArray(manifest)) {
        return { ok: false, errors: ["o manifesto precisa ser um objeto JSON"] };
    }
    if (!SEGMENT.test(manifest.id ?? ""))
        errors.push(`id "${manifest.id}" precisa ser um segmento minusculo, sem ponto`);
    if (!SEMVER.test(manifest.version ?? ""))
        errors.push(`version "${manifest.version}" precisa ser semver (1.2.3)`);
    if (!Number.isInteger(manifest.pluginApi))
        errors.push(`pluginApi "${manifest.pluginApi}" precisa ser um inteiro`);
    if (typeof manifest.author !== "string" || manifest.author.length === 0)
        errors.push("author precisa estar preenchido");

    stringList(manifest.modules, "modules", errors, pathProblem);
    stringList(manifest.faces, "faces", errors, pathProblem);
    stringList(manifest.services, "services", errors, (entry, label) =>
        typeof entry === "string" && SEGMENT.test(entry) ? null : `${label} precisa ser um nome de service`);

    return { ok: errors.length === 0, errors };
}

export function validateModuleMeta(meta) {
    const errors = [];
    if (!meta || typeof meta !== "object" || Array.isArray(meta))
        return { ok: false, errors: ["o meta do module precisa ser um objeto JSON"] };
    if (!SEGMENT.test(meta.module ?? ""))
        errors.push(`module "${meta.module}" precisa ser um segmento minusculo, sem o prefixo do plugin`);
    if (typeof meta.title !== "string" || meta.title.length === 0) errors.push("title precisa estar preenchido");
    const componentProblem = pathProblem(meta.component, "component");
    if (componentProblem) errors.push(componentProblem);
    else if (!meta.component.endsWith(".qml")) errors.push("component precisa ser um .qml");
    if (!SEGMENT.test(meta.defaultFace ?? "")) errors.push("defaultFace precisa nomear uma face");
    stringList(meta.services, "services", errors, (entry, label) =>
        typeof entry === "string" ? null : `${label} precisa ser um nome de service`);
    if (meta.placeable !== undefined && typeof meta.placeable !== "boolean")
        errors.push("placeable precisa ser booleano");
    if (meta.placeable) {
        const cell = meta.defaultCell;
        if (!cell || !Number.isInteger(cell.w) || !Number.isInteger(cell.h) || cell.w < 1 || cell.h < 1)
            errors.push("um module placeable precisa de defaultCell { w, h } em celulas");
    }
    if (meta.provides !== undefined) {
        if (!Array.isArray(meta.provides)) errors.push("provides precisa ser uma lista");
        else meta.provides.forEach((entry, i) => {
            if (!entry || typeof entry.name !== "string" || entry.name.length === 0)
                errors.push(`provides[${i}] precisa ter name`);
            if (!["string", "int", "real", "bool", "var"].includes(entry?.kind))
                errors.push(`provides[${i}].kind "${entry?.kind}" nao e um tipo QML conhecido`);
            if (typeof entry?.doc !== "string" || entry.doc.length <= 10)
                errors.push(`provides[${i}] precisa de doc (3.5b pede documentar, nao so listar)`);
        });
    }
    return { ok: errors.length === 0, errors };
}

export function validateFaceMeta(meta) {
    const errors = [];
    if (!meta || typeof meta !== "object" || Array.isArray(meta))
        return { ok: false, errors: ["o meta da face precisa ser um objeto JSON"] };
    if (!SEGMENT.test(meta.face ?? "")) errors.push(`face "${meta.face}" precisa ser um segmento minusculo`);
    // O module vem com o nome COMPLETO, de proposito: uma face pode vestir
    // um module de outro plugin (e o caso que faz "qualquer um escreve
    // estilos" ser verdade), entao ela precisa poder nomear quem nao e dela.
    if (!MODULE_ID.test(meta.module ?? ""))
        errors.push(`module "${meta.module}" precisa ser o nome completo, plugin.module`);
    if (typeof meta.title !== "string" || meta.title.length === 0) errors.push("title precisa estar preenchido");
    const componentProblem = pathProblem(meta.component, "component");
    if (componentProblem) errors.push(componentProblem);
    else if (!meta.component.endsWith(".qml")) errors.push("component precisa ser um .qml");
    if (meta.options !== undefined && !Array.isArray(meta.options)) errors.push("options precisa ser uma lista");
    return { ok: errors.length === 0, errors };
}
