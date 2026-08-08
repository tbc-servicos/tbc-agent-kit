#!/usr/bin/env bash
# advpl-encoding-pre.sh — bloqueia Edit/Write em fonte CP-1252 ANTES da corrupção
# Ativado por PreToolUse (Write|Edit)
#
# Por quê PRE e não só o advpl-encoding.sh (PostToolUse): quando o Edit lê um .prw
# CP-1252 assumindo UTF-8, os bytes altos viram U+FFFD e o arquivo é regravado já
# corrompido — o hook Post detecta, mas os acentos originais JÁ se perderam. Este
# hook barra a ferramenta antes da leitura destrutiva. O advpl-encoding.sh
# continua como rede de segurança pós-gravação.

set -euo pipefail

if ! command -v jq &>/dev/null; then
  echo "⚠️  ENCODING(pre): jq não encontrado — verificação ignorada"
  exit 0
fi

INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Sem caminho, arquivo novo (Write de arquivo inexistente) ou não-ADVPL: não interfere
[[ -z "$FILE" || ! -f "$FILE" ]] && exit 0
case "$FILE" in
  *.prw|*.PRW|*.tlpp|*.TLPP) ;;
  *) exit 0 ;;
esac

command -v python3 &>/dev/null || exit 0

# Mesma detecção do advpl-encoding.sh: CP1252 = bytes altos que não decodificam UTF-8
ENCODING_STATE=$(python3 - "$FILE" <<'PYEOF'
import sys

filepath = sys.argv[1]
with open(filepath, 'rb') as f:
    data = f.read()

if not data or all(b < 128 for b in data):
    print("ASCII")
    sys.exit(0)

if data.startswith(b'\xef\xbb\xbf'):
    print("UTF8")
    sys.exit(0)

try:
    data.decode('utf-8')
    print("UTF8")
except UnicodeDecodeError:
    print("CP1252")
PYEOF
)

if [[ "$ENCODING_STATE" == "CP1252" ]]; then
  BASENAME=$(basename "$FILE")
  cat >&2 <<EOMSG
🚫 ENCODING: '$BASENAME' está em CP-1252 com acentos. Edit/Write leem UTF-8 e
corromperiam os acentos em U+FFFD de forma IRREVERSÍVEL (o hook pós-gravação só
avisaria depois do estrago).

Edite via script Python preservando o charset (copie como está — heredoc e código
na coluna 0):

python3 - <<'PY'
p = r'$FILE'
s = open(p, encoding='cp1252', newline='').read()
s = s.replace('<antigo>', '<novo>')
open(p, 'w', encoding='cp1252', newline='').write(s)
PY

Confirme depois com: file "$FILE"  (deve reportar ISO-8859).
EOMSG
  exit 2
fi

exit 0
