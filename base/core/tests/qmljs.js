// Loads the shell's QML JS libraries in node, for the tests: strips `.pragma library`, resolves each
// `.import "x.js" as Y` from the file (that is how a generated index pulls in every meta.js) and hands
// the result in as an argument. Shared by the tests of every area; it ships with them.
const fs = require("fs");
const path = require("path");

// the shell's root: the folder above the caller's with shell.qml (the tests move with their code)
function rootOf(dir) {
    while (!fs.existsSync(path.join(dir, "shell.qml")))
        dir = path.dirname(dir);
    return dir;
}

function make(root) {
    const read = f => fs.readFileSync(path.join(root, f), "utf8");
    const strip = f => read(f).replace(/^\.(pragma|import).*$/mg, "");

    // the file's `.import`s, resolved and ready to be passed as arguments
    function deps(f) {
        const args = [], vals = [];
        for (const m of read(f).matchAll(/^\.import "([^"]+)" as (\w+)$/gm)) {
            args.push(m[2]);
            vals.push(auto(path.join(path.dirname(f), m[1])));
        }
        return [args, vals];
    }

    // every `var` and `function` the library declares
    function auto(f) {
        const names = [...read(f).matchAll(/^(?:var|function) (\w+)/gm)].map(m => m[1]);
        return lib(f, names);
    }

    // the names asked for, plus `args` / `vals` for what the library expects from outside
    function lib(f, names, args = [], vals = []) {
        const [dargs, dvals] = deps(f);
        return new Function(...args.concat(dargs), strip(f) + "\nreturn {" + names.join(",") + "};")(...vals.concat(dvals));
    }

    return { read, strip, lib, auto };
}

module.exports = { rootOf, make };
