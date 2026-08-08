#!/usr/bin/env bash
# Testes do advpl-encoding-pre.sh (PreToolUse — bloqueia Edit/Write em CP-1252)
set -uo pipefail

HOOK="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/protheus/hooks/advpl-encoding-pre.sh"
TMPDIR=$(mktemp -d); trap 'rm -rf "$TMPDIR"' EXIT
FAIL=0

run_hook() { # $1 = file path
  echo "{\"tool_input\":{\"file_path\":\"$1\"}}" | bash "$HOOK" 2>"$TMPDIR/err"
}

echo "T1 — .prw CP-1252 com acentos bloqueia (exit 2, instrução Python)"
printf 'Local cMsg := "Valida\xe7\xe3o"\n' > "$TMPDIR/RFAT.prw"   # ç/ã em CP-1252
run_hook "$TMPDIR/RFAT.prw"; RC=$?
if [[ $RC -eq 2 ]] && grep -q "cp1252" "$TMPDIR/err"; then echo "  ✅ block com instrução"; else echo "  ❌ RC=$RC"; FAIL=1; fi

echo "T2 — .prw UTF-8 passa (o Post cuida da conversão)"
printf 'Local cMsg := "Validação"\n' > "$TMPDIR/RUTF.prw"
run_hook "$TMPDIR/RUTF.prw"; RC=$?
[[ $RC -eq 0 ]] && echo "  ✅ passa" || { echo "  ❌ RC=$RC"; FAIL=1; }

echo "T3 — .prw ASCII puro passa"
printf 'Local nQtd := 0\n' > "$TMPDIR/RASC.prw"
run_hook "$TMPDIR/RASC.prw"; RC=$?
[[ $RC -eq 0 ]] && echo "  ✅ passa" || { echo "  ❌ RC=$RC"; FAIL=1; }

echo "T4 — arquivo novo (inexistente) passa"
run_hook "$TMPDIR/NOVO.prw"; RC=$?
[[ $RC -eq 0 ]] && echo "  ✅ passa" || { echo "  ❌ RC=$RC"; FAIL=1; }

echo "T5 — extensão não-ADVPL passa mesmo em CP-1252"
printf '\xe7\xe3o\n' > "$TMPDIR/nota.txt"
run_hook "$TMPDIR/nota.txt"; RC=$?
[[ $RC -eq 0 ]] && echo "  ✅ passa" || { echo "  ❌ RC=$RC"; FAIL=1; }

[[ $FAIL -eq 0 ]] && echo "TODOS OS TESTES PASSARAM" || { echo "FALHAS"; exit 1; }
