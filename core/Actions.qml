pragma Singleton

import QtQuick
import Quickshell
import qs.services

// Runs the screen tools' and the session's actions by id (apps/tools/actions.js,
// apps/session/actions.js), for the Tools / Session apps, their Qwidgets and IPC. Each runs after the
// island closed (Runtime.closeThen), so it never shows in a capture and the session ends cleanly.
Singleton {
    id: root

    function runTool(id: string) {
        const monitor = Hypr.focusedScreen;
        switch (id) {
        case "shot-region":
            return Runtime.closeThen(() => ScreenTools.screenshot("region", monitor));
        case "shot-screen":
            return Runtime.closeThen(() => ScreenTools.screenshot("screen", monitor));
        case "rec-region":
            return Runtime.closeThen(() => ScreenTools.startRecording("region", monitor));
        case "rec-screen":
            return Runtime.closeThen(() => ScreenTools.startRecording("screen", monitor));
        case "rec-audio":
            return Runtime.closeThen(() => ScreenTools.startRecording("audio", monitor));
        case "stop":
            Runtime.closeApp();
            return ScreenTools.stopRecording();
        case "picker":
            return Runtime.closeThen(() => ScreenTools.pickColor());
        case "ocr":
            return Runtime.closeThen(() => ScreenTools.ocr());
        }
    }

    function runSession(id: string) {
        Runtime.closeThen(() => Session.run(id));
    }
}
