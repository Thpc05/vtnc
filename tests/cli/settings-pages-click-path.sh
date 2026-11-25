#!/usr/bin/env bash
# 0.508 critério 5: acrescentar um widget pela página Pages passa pela CLI e
# chega ao config.json. Mesma restrição de Quickshell.shellDir dos outros
# harnesses de tests/cli: roda de uma cópia descartável na raiz do vtnc-dev,
# com o import reescrito.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
tmp_config_dir=$(mktemp -d)
harness="$here/.settings-pages-click-path-test.qml"
fail=0

cleanup() {
    rm -f "$harness"
    rm -rf "$tmp_config_dir"
}
trap cleanup EXIT

sed 's#\.\./\.\./modules/pages-editor#./modules/pages-editor#' \
    "$here/tests/cli/settings-pages-click-path.qml" >"$harness"

cat >"$tmp_config_dir/config.json" <<'EOF'
{
  "cell": { "base": 8 },
  "monitors": {},
  "islands": [],
  "pages": { "dash": { "grid": { "cols": 10, "rows": 4 }, "widgets": [] } }
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

check "o chip + Clock foi achado no Panel construído" \
    "$(echo "$log" | grep -c 'PAGESCLICKPATH: clicking the add-clock chip')" "1"

widgets_after=$(python3 -c 'import json; print(json.dumps(json.load(open("'"$tmp_config_dir"'/config.json"))["pages"]["dash"]["widgets"]))')
check "clicar acrescentou o clock à page, pela CLI" \
    "$(echo "$widgets_after" | python3 -c 'import json,sys; w=json.load(sys.stdin); print("%s %sx%s" % (w[0]["module"], w[0]["cell"]["w"], w[0]["cell"]["h"]))')" \
    "vtnc.clock 6x2"

[[ $fail -ne 0 ]] && echo "--- log:" && echo "$log"
exit $fail
