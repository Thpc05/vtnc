import QtQuick
import Quickshell
import "../core"

// A page: a reusable group of widget instances with its own grid (decision
// 1b.0 / 1b.3 / 6.1). The page owns the widget instances — swap which page
// an island wears and its widgets go with it.
//
// 0.512: this file no longer knows a single module by name. Until now it
// held a `switch` over every module the shell shipped, which is precisely
// why nothing outside the shell folder could ever be drawn. Now it asks
// the registry where the module's QML is and loads it from there.
Item {
    id: root

    required property var pageConfig // { grid: {cols, rows}, widgets: [{module, face, cell:{x,y,w,h}}] }
    required property real cellPx

    // MEDIDO, e e a coisa mais importante que este passo descobriu: um QML
    // carregado por URL ABSOLUTA cai num contexto de tipos proprio, e todo
    // `pragma Singleton` que ele importar vira uma SEGUNDA instancia. O
    // Clock.qml carregado assim acquire() num ServiceRegistry que nao e o
    // da shell - o service liga, e o `service get` da CLI continua
    // dizendo que esta desligado. Carregado por caminho relativo, dentro
    // da arvore da shell, e o mesmo singleton (comparado pelo id do tipo:
    // ServiceRegistry_QMLTYPE_12 nos dois lados).
    //
    // Entao o module embutido carrega relativo, que e como ele sempre
    // carregou, e o de terceiro carrega absoluto - fora da arvore nao
    // existe caminho relativo que ajude. A consequencia para o plugin de
    // terceiro esta escrita no README de modules/: importar as entranhas
    // da shell NAO da acesso a shell, da uma copia paralela dela. O canal
    // que atravessa a fronteira de verdade e o das propriedades
    // injetadas, e e por ele que a camada servico vai passar (0.513).
    function loadUrl(componentUrl) {
        const prefix = "file://" + Quickshell.shellDir + "/";
        return componentUrl.startsWith(prefix) ? "../" + componentUrl.slice(prefix.length) : componentUrl;
    }

    Repeater {
        model: root.pageConfig.widgets ?? []

        delegate: Loader {
            id: widgetLoader
            required property var modelData

            x: (modelData.cell?.x ?? 0) * root.cellPx
            y: (modelData.cell?.y ?? 0) * root.cellPx
            width: (modelData.cell?.w ?? 1) * root.cellPx
            height: (modelData.cell?.h ?? 1) * root.cellPx

            // The registry is rebuilt whenever a plugin folder is scanned,
            // so this is a binding on the catalog, not a one-off read: a
            // module that was missing a moment ago starts drawing by
            // itself once its plugin loads.
            readonly property string moduleUrl:
                PluginRegistry.catalog ? PluginRegistry.moduleUrl(modelData.module) : ""

            onModuleUrlChanged: widgetLoader.load()
            Component.onCompleted: widgetLoader.load()

            function load() {
                if (widgetLoader.moduleUrl === "") {
                    widgetLoader.source = "";
                    return;
                }
                widgetLoader.setSource(root.loadUrl(widgetLoader.moduleUrl), {
                    widgetConfig: Qt.binding(() => widgetLoader.modelData)
                });
            }
        }
    }
}
