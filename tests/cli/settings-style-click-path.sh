#!/usr/bin/env bash
# 0.509 critério 4: trocar o style de um widget pela página Pages passa pela
# CLI e chega ao config.json. Mesma restrição de Quickshell.shellDir dos outros
# harnesses de tests/cli: roda de uma cópia descartável na raiz do vtnc-dev,
# com o import reescrito.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
tmp_config_dir=$(mktemp -d)
harness="$here/.settings-style-click-path-test.qml"
fail=0

cleanup() {
    rm -f "$harness"
    rm -rf "$tmp_config_dir"
}
trap cleanup EXIT

sed 's#\.\./\.\./widgets/pages-editor#./widgets/pages-editor#' \
    "$here/tests/cli/settings-style-click-path.qml" >"$harness"

cat >"$tmp_config_dir/config.json" <<'EOF'
{
  "cell": { "base": 8 },
  "monitors": {},
  "islands": [],
  "pages": { "dash": { "grid": { "cols": 10, "rows": 4 },
    "widgets": [ { "type": "vtnc.clock", "cell": { "x": 0, "y": 0, "w": 6, "h": 2 } } ] } }
}
EOF

check() {
    local desc="$1" got="$2" expected="$3"
    if [[ "$got" == "$expected" ]]; then
        echo "OK: $desc"
    else
        echo "FAIL: $desc — esperado [$expected], obtido [$got]"
        fail=1
    fi
}

log=$(VTNC_CONFIG_DIR="$tmp_config_dir" QT_QPA_PLATFORM=offscreen \
    timeout 10 qs -p "$harness" -n 2>&1 || true)

check "o chip do style Compact foi achado no Panel construído" \
    "$(echo "$log" | grep -c 'STYLECLICKPATH: clicking the compact style chip')" "1"

widgets_after=$(python3 -c 'import json; print(json.dumps(json.load(open("'"$tmp_config_dir"'/config.json"))["pages"]["dash"]["widgets"]))')
check "clicar vestiu o style Compact naquele widget, pela CLI" \
    "$(echo "$widgets_after" | python3 -c 'import json,sys; w=json.load(sys.stdin); print(w[0]["style"])')" \
    "compact"

# A troca de style não pode levar a célula junto: o usuário escolheu aquele
# lugar e aquele tamanho, e mexer neles seria mudar configuração que ele não
# pediu para mudar.
check "e não mexeu na célula do widget" \
    "$(echo "$widgets_after" | python3 -c 'import json,sys; c=json.load(sys.stdin)[0]["cell"]; print("%s,%s %sx%s" % (c["x"], c["y"], c["w"], c["h"]))')" \
    "0,0 6x2"

[[ $fail -ne 0 ]] && echo "--- log:" && echo "$log"
exit $fail
