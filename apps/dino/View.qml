import QtQuick
import qs.core
import qs.theme
import qs.kit as K
import qs.dwidgets.quick.panels
import "sprites.js" as Sprites

// Dino run (2026-10-17): Chrome's offline game on the island. Space / ↑ jumps (held: higher), ↓ ducks
// (in the air: falls fast), a click jumps; Space / Enter restarts after a crash. Cacti first, birds
// once it's fast enough; the speed grows; night every 700 points. High score in state.json
// (apps.dino.highscore). Chrome's pixel sprites in the theme's colours (user: only "vtnc colors"): the
// dino in the accent, the rest in the look's ink, on the apps' look (K.Kit.appStyle). Settings → Apps →
// Dino run: the start speed. Closing the app pauses it.
// Chrome's units: px per frame at 60 fps (gravity 0.6, jump -10, speed 6 → 13).
FocusScope {
    id: root

    readonly property var cfg: Store.appOptions.dino
    readonly property real startSpeed: (cfg?.speed ?? "normal") === "fast" ? 9 : 6

    readonly property PanelColors c: PanelColors {
        look: K.Kit.appLook
    }

    implicitWidth: 720
    implicitHeight: 220

    // the world -----------------------------------------------------------------
    readonly property real groundY: field.height - 16
    readonly property real dinoX: 40

    // "ready" (before the first jump) · "running" · "paused" · "over"
    property string status: "ready"
    property real speed: startSpeed
    property real distance: 0
    readonly property int score: Math.floor(distance * 0.025)
    property int highscore: Store.appGet("dino", "highscore", 0)
    property bool newHigh: false
    readonly property bool night: Math.floor(score / 700) % 2 === 1

    // the dino: its feet's height above the ground (0 = on it), velocity, ducking, its run frame
    property real jumpY: 0
    property real velocity: 0
    property bool jumping: false
    property bool jumpHeld: false
    property bool ducking: false
    property real legTime: 0
    readonly property int legFrame: status !== "running" || jumping ? 0 : 1 + Math.floor(legTime / 0.1) % 2

    // [{ kind: "cactus" | "bird", x, y (top), w, h, arms, flap }]
    property var obstacles: []
    property var clouds: []
    property real groundOffset: 0

    function reset() {
        speed = startSpeed;
        distance = 0;
        jumpY = 0;
        velocity = 0;
        jumping = false;
        ducking = false;
        obstacles = [];
        clouds = [{
                x: 300,
                y: 30
            }, {
                x: 560,
                y: 55
            }];
        newHigh = false;
    }

    function start() {
        if (status === "over")
            reset();
        status = "running";
    }

    function jump() {
        if (status !== "running") {
            start();
            if (status !== "running")
                return;
        }
        if (!jumping && !ducking) {
            jumping = true;
            velocity = -10 - speed / 10;
        }
    }

    function crash() {
        status = "over";
        if (score > highscore) {
            highscore = score;
            newHigh = true;
            Store.appSet("dino", "highscore", score);
        }
        // the last runs, newest first (the dashboard's Dino summary)
        if (score > 0)
            Store.appSet("dino", "runs", [{
                    score: score,
                    time: Date.now()
                }].concat(Store.appGet("dino", "runs", [])).slice(0, 20));
    }

    // the dino's hit box (Chrome's are a few boxes; one shrunk box is close)
    function dinoBox(): var {
        const s = Sprites.size(ducking ? Sprites.DUCK[0] : Sprites.DINO_BODY.concat(Sprites.DINO_LEGS[0]));
        return {
            x: dinoX + 6,
            y: groundY - s.h - jumpY + 4,
            w: s.w - 14,
            h: s.h - 8
        };
    }

    function spawn() {
        const last = obstacles[obstacles.length - 1];
        const birdsOk = speed > 8.5 && score > 450;
        let o;
        if (birdsOk && Math.random() < 0.3) {
            const s = Sprites.size(Sprites.BIRD[0]);
            const heights = [groundY - s.h - 2, groundY - s.h - 32, groundY - s.h - 62];
            o = {
                kind: "bird",
                w: s.w,
                h: s.h,
                y: heights[Math.floor(Math.random() * heights.length)],
                flap: 0
            };
        } else {
            const large = Math.random() < 0.4;
            const count = 1 + Math.floor(Math.random() * (speed > 8 ? 3 : 2));
            const w = (large ? 16 : 12) * count + (count - 1) * 2;
            const h = large ? 48 : 34;
            o = {
                kind: "cactus",
                w: w,
                h: h,
                y: groundY - h,
                count: count,
                large: large,
                arms: Math.random()
            };
        }
        o.x = field.width + 10;
        // the gap after the last one grows with the speed (Chrome: width × speed + 120 × 0.6, up to 1.5×)
        const minGap = (last?.w ?? 20) * speed + 72;
        o.gap = minGap + Math.random() * minGap * 0.5;
        obstacles = obstacles.concat([o]);
    }

    function hit(a: var, b: var): bool {
        return a.x < b.x + b.w && a.x + a.w > b.x && a.y < b.y + b.h && a.y + a.h > b.y;
    }

    function tick(dt: real) {
        const f = Math.min(dt, 0.05) * 60;
        legTime += dt;
        speed = Math.min(13, speed + 0.001 * f);
        distance += speed * f;
        groundOffset = (groundOffset + speed * f) % 48;

        // the jump: a released key cuts it short (Chrome's drop velocity)
        if (jumping) {
            if (!jumpHeld && velocity < -5)
                velocity = -5;
            jumpY -= velocity * f;
            velocity += (ducking ? 1.8 : 0.6) * f;
            if (jumpY <= 0) {
                jumpY = 0;
                velocity = 0;
                jumping = false;
            }
        }

        const moved = [];
        for (const o of obstacles) {
            const n = Object.assign({}, o);
            n.x -= (n.kind === "bird" ? speed + 0.8 : speed) * f;
            if (n.kind === "bird")
                n.flap = (n.flap + dt) % 0.34;
            if (n.x + n.w > -10)
                moved.push(n);
        }
        obstacles = moved;
        const last = obstacles[obstacles.length - 1];
        if (!last || field.width - (last.x + last.w) > last.gap)
            spawn();

        clouds = clouds.map(cl => ({
                    x: cl.x - 0.2 * speed * f,
                    y: cl.y
                })).filter(cl => cl.x > -60);
        if (clouds.length < 3 && Math.random() < 0.004 * f)
            clouds = clouds.concat([{
                    x: field.width + 20,
                    y: 20 + Math.random() * 50
                }]);

        const d = dinoBox();
        for (const o of obstacles) {
            const box = {
                x: o.x + 4,
                y: o.y + 4,
                w: o.w - 8,
                h: o.h - 6
            };
            if (hit(d, box)) {
                crash();
                break;
            }
        }
    }

    FrameAnimation {
        id: loop
        running: root.status === "running" && root.visible
        onTriggered: {
            root.tick(frameTime);
            canvas.requestPaint();
        }
    }

    // (a paused game waits for a key; `play` from the dashboard's summary starts a new one)
    function opened(args) {
        forceActiveFocus();
        if (args?.play && status !== "running") {
            reset();
            start();
        }
        canvas.requestPaint();
    }
    function closed() {
        if (status === "running")
            status = "paused";
        jumpHeld = false;
        ducking = false;
    }

    Component.onCompleted: reset()
    onNightChanged: canvas.requestPaint()

    Keys.onPressed: e => {
        if (e.isAutoRepeat) {
            e.accepted = true;
            return;
        }
        if (e.key === Qt.Key_Space || e.key === Qt.Key_Up || e.key === Qt.Key_W) {
            jumpHeld = true;
            if (status === "over" || status === "paused" || status === "ready")
                start();
            if (status === "running")
                jump();
        } else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
            if (status !== "running")
                start();
        } else if (e.key === Qt.Key_Down || e.key === Qt.Key_S) {
            if (status === "running")
                ducking = true;
        } else
            return;
        e.accepted = true;
    }
    Keys.onReleased: e => {
        if (e.isAutoRepeat)
            return;
        if (e.key === Qt.Key_Space || e.key === Qt.Key_Up || e.key === Qt.Key_W)
            jumpHeld = false;
        else if (e.key === Qt.Key_Down || e.key === Qt.Key_S)
            ducking = false;
    }

    // the score ---------------------------------------------------------------
    Row {
        id: hud
        anchors.right: parent.right
        anchors.rightMargin: 8
        height: 24
        spacing: 16

        K.StyledText {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.highscore > 0
            text: "HI " + String(root.highscore).padStart(5, "0")
            font.family: K.Kit.clockFamily
            font.pixelSize: 14
            font.weight: Font.Medium
            font.features: ({
                    "tnum": 1
                })
            color: root.c.weak
        }
        K.StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: String(root.score).padStart(5, "0")
            font.family: K.Kit.clockFamily
            font.pixelSize: 14
            font.weight: Font.Bold
            font.features: ({
                    "tnum": 1
                })
            color: root.c.strong
            // Chrome blinks it every 100 points
            opacity: root.status === "running" && root.score > 0 && root.score % 100 < 3 ? 0.3 : 1
        }
    }

    // the field ---------------------------------------------------------------
    Rectangle {
        id: field
        anchors.top: hud.bottom
        anchors.topMargin: 4
        anchors.bottom: parent.bottom
        width: parent.width
        radius: K.Kit.rounding.large
        // night: the colours turn over
        color: root.night ? Colors.inverseSurface : root.c.shapes ? K.Kit.expressive.container : root.c.kind === "tones" ? Qt.tint(K.Kit.expressive.container, Qt.alpha(root.c.accent, 0.08)) : "transparent"
        border.width: root.c.kind === "tone" && !root.night ? 1 : 0
        border.color: Qt.alpha(root.c.accent, 0.25)
        clip: true
        Behavior on color {
            K.CAnim {}
        }

        // the look's strong ink, the dino in the accent
        readonly property color ink: root.night ? Colors.surface : root.c.strong
        readonly property color soft: Qt.alpha(ink, 0.35)
        readonly property color accent: root.night ? Colors.inversePrimary : root.c.accent

        Canvas {
            id: canvas
            anchors.fill: parent
            renderStrategy: Canvas.Cooperative

            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                root.paint(ctx);
            }
        }

        // ready / paused / over
        Column {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -16
            visible: root.status !== "running"
            spacing: 4

            K.StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.status === "over" ? (root.newHigh ? "New high score" : "Game over") : root.status === "paused" ? "Paused" : "Dino run"
                font.family: K.Kit.family
                font.variableAxes: K.Kit.axes
                font.pixelSize: 17
                font.weight: Font.Bold
                color: root.newHigh && root.status === "over" ? field.accent : field.ink
            }
            K.StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.status === "over" ? "Space to play again" : "Space or click to " + (root.status === "paused" ? "go on" : "start")
                font.family: K.Kit.family
                font.variableAxes: K.Kit.axes
                font.pixelSize: 12
                color: Qt.alpha(field.ink, 0.7)
            }
        }

        MouseArea {
            anchors.fill: parent
            onPressed: {
                root.forceActiveFocus();
                root.jumpHeld = true;
                if (root.status === "running")
                    root.jump();
                else
                    root.start();
            }
            onReleased: root.jumpHeld = false
        }
    }

    // painting ------------------------------------------------------------------
    function paint(ctx) {
        const ink = field.ink;
        const gy = Math.round(groundY);
        // the ground: a line with bumps scrolling by
        ctx.fillStyle = field.soft;
        ctx.fillRect(0, gy - 1, field.width, 1);
        ctx.fillStyle = field.soft;
        for (let x = -Math.round(groundOffset); x < field.width; x += 48) {
            ctx.fillRect(x + 6, gy + 4, 4, 1);
            ctx.fillRect(x + 27, gy + 8, 2, 1);
            ctx.fillRect(x + 38, gy + 3, 6, 1);
        }
        // clouds
        ctx.fillStyle = field.soft;
        for (const cl of clouds)
            Sprites.draw(ctx, Sprites.CLOUD, cl.x, cl.y);
        ctx.fillStyle = ink;
        for (const o of obstacles) {
            if (o.kind === "bird")
                Sprites.draw(ctx, Sprites.BIRD[o.flap < 0.17 ? 0 : 1], Math.round(o.x), Math.round(o.y));
            else
                paintCactusPixels(ctx, o);
        }
        // the dino, in the accent
        ctx.fillStyle = field.accent;
        const over = status === "over";
        if (ducking && !over) {
            const s = Sprites.DUCK[legFrame % 2];
            Sprites.draw(ctx, s, dinoX, groundY - Sprites.size(s).h - jumpY);
        } else {
            const rows = (over ? Sprites.DINO_DEAD_HEAD.concat(Sprites.DINO_BODY.slice(4)) : Sprites.DINO_BODY).concat(Sprites.DINO_LEGS[legFrame]);
            Sprites.draw(ctx, rows, dinoX, groundY - Sprites.size(rows).h - jumpY);
        }
    }

    // a cactus group: trunks with arms, in 2 px cells
    function paintCactusPixels(ctx, o) {
        // whole pixels, 2 px steps: no seams
        const R = v => 2 * Math.round(v / 2);
        const each = o.large ? 16 : 12;
        const y = Math.round(o.y);
        for (let i = 0; i < o.count; i++) {
            const x = Math.round(o.x) + i * (each + 2);
            const trunk = o.large ? 6 : 4;
            const tx = x + (each - trunk) / 2;
            ctx.fillRect(tx, y, trunk, o.h);
            const armY = y + R(o.h * (0.3 + 0.2 * ((o.arms * (i + 1) * 7) % 1)));
            const armH = R(o.h * 0.25);
            // left arm
            ctx.fillRect(x, armY, 2, armH);
            ctx.fillRect(x, armY + armH - 2, tx - x, 2);
            // right arm
            const rY = y + R(o.h * 0.2);
            const rH = R(o.h * 0.22);
            ctx.fillRect(x + each - 2, rY, 2, rH);
            ctx.fillRect(tx + trunk, rY + rH - 2, x + each - (tx + trunk), 2);
        }
    }
}
