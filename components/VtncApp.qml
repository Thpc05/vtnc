import QtQuick

// Definition of an island app. Each app lives in apps/<id>/ with an App.qml like:
//
//   VtncApp {
//       appId: "session"
//       title: "Sessão"
//       icon: Icons.power
//       view: Component { View {} }
//   }
//
// The view's implicit size is what the island morphs to. Inside the view:
//   - `close()` it with Runtime.closeApp() (or Runtime.closeThen(fn) to act after closing)
//   - optional `function opened(args)` is called every time the app is opened
//   - optional `function closed()` is called every time the app is closed
QtObject {
    required property string appId
    property string title: appId
    property string icon: ""
    property Component view: null

    // keep the view alive after the first open (state survives closing)
    property bool keepAlive: true
    // Esc closes the app
    property bool closeOnEsc: true
}
