#!/usr/bin/env bash
# fluig-lint.sh — Lint JS/TS/HTML para desenvolvimento Fluig
# Ativado por PostToolUse (Write|Edit)
#
# Dois mundos, convenções OPOSTAS:
# - SERVER-SIDE (ds_*.js, wf_*.js, events/, Util/): Rhino/ECMA 5 — let/const/arrow/class
#   quebram NO SERVIDOR; o config eslint.server.config.mjs do plugin torna isso erro de
#   parse aqui. Roda SEMPRE, mesmo sem @po-ui no package.json (repo de datasets puro).
# - WIDGET (.ts/.html em projeto @po-ui): ES moderno; usa o eslint do projeto, com
#   fallback para o config do plugin.

set -euo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Ignorar se sem caminho (ex: NotebookEdit)
if [[ -z "$FILE_PATH" ]]; then
  exit 0
fi

# Ignorar se arquivo não existe
if [[ ! -f "$FILE_PATH" ]]; then
  exit 0
fi

EXT="${FILE_PATH##*.}"

# Só age em JS, TS e HTML
case "$EXT" in
  js|ts|html) ;;
  *) exit 0 ;;
esac

# Ignorar arquivos gerados/minificados
if [[ "$FILE_PATH" == *.min.js ]] || \
   [[ "$FILE_PATH" == *.d.ts ]] || \
   [[ "$FILE_PATH" == */dist/* ]] || \
   [[ "$FILE_PATH" == */.angular/* ]]; then
  exit 0
fi

CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
[[ -z "$CWD" ]] && CWD="$(dirname "$FILE_PATH")"

# Assets do plugin (configs ESLint) — CLAUDE_PLUGIN_ROOT quando disponível,
# senão relativo a este script (hooks/ → skills/test/assets/)
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
SERVER_CONFIG="$PLUGIN_ROOT/skills/test/assets/eslint.server.config.mjs"
WIDGET_CONFIG="$PLUGIN_ROOT/skills/test/assets/eslint.widget.config.mjs"

BASENAME=$(basename "$FILE_PATH")

# Roteamento: server-side Fluig se bater no padrão de nome/caminho
is_server_side() {
  [[ "$EXT" != "js" ]] && return 1
  [[ "$BASENAME" == *.spec.js || "$BASENAME" == *.test.js ]] && return 1
  [[ "$BASENAME" == ds_* ]] && return 0
  [[ "$BASENAME" == wf_* ]] && return 0
  [[ "$FILE_PATH" == */events/* ]] && return 0
  [[ "$FILE_PATH" == */Util/* ]] && return 0
  return 1
}

is_fluig_project() {
  local dir="$1"
  for i in 1 2 3 4; do
    local pkg="$dir/package.json"
    if [[ -f "$pkg" ]] && jq -e '(.dependencies["@po-ui/ng-components"] // .devDependencies["@po-ui/ng-components"]) != null' "$pkg" &>/dev/null 2>&1; then
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  return 1
}

ERRORS=""

# ============ ROTA SERVER-SIDE — roda SEMPRE, independe de @po-ui ============
if is_server_side; then
  LINTED=0
  if command -v npx &>/dev/null && [[ -f "$SERVER_CONFIG" ]]; then
    ESLINT_EXIT=0
    # cd para o diretório do arquivo: ESLint flat config ignora ("outside of base
    # path", exit 0) arquivo fora do cwd — rodar de outro diretório silencia o gate
    ESLINT_OUT=$(cd "$(dirname "$FILE_PATH")" && npx --no-install eslint --config "$SERVER_CONFIG" "$(basename "$FILE_PATH")" 2>&1) || ESLINT_EXIT=$?
    # exit 1 = achado de lint (bloqueia com a saída); exit >= 2 ou eslint ausente =
    # falha da FERRAMENTA (config inválido, versão sem flat config, não instalado) —
    # não é culpa do código do dev: cai no fallback de greps
    if [[ $ESLINT_EXIT -le 1 ]] && ! echo "$ESLINT_OUT" | grep -qiE "not found|command failed|could not determine"; then
      LINTED=1
      if [[ $ESLINT_EXIT -eq 1 ]]; then
        ERRORS+="ESLint (server-side Rhino/ES5):\n${ESLINT_OUT}\n"
      fi
    fi
  fi

  # Fallback sem eslint: greps mínimos (melhor que zero gate)
  if [[ $LINTED -eq 0 ]]; then
    if grep -qE '(^|[^A-Za-z_])(const |let |=>|class )' "$FILE_PATH" 2>/dev/null; then
      ERRORS+="Fluig server-side: const/let/arrow/class detectado — o motor do Fluig é Rhino ECMA 5; use var e function\n"
    fi
    if grep -q 'alert(' "$FILE_PATH" 2>/dev/null; then
      ERRORS+="Fluig: uso de alert() proibido\n"
    fi
  fi

  # Regras estruturais (sempre)
  if [[ "$BASENAME" == ds_* ]] || [[ "$BASENAME" == wf_* ]]; then
    if ! grep -qE '^[[:space:]]*try[[:space:]]*\{' "$FILE_PATH" 2>/dev/null; then
      ERRORS+="Fluig: '${BASENAME}' não tem try/catch — obrigatório em datasets e workflows\n"
    fi
  fi

  if [[ -n "$ERRORS" ]]; then
    jq -n --arg reason "Qualidade Fluig — corrija antes de continuar:\n\n${ERRORS}\nRegra errada para este caso? Registre: /fluig:feedback" \
      '{"decision":"block","reason":$reason}'
  fi
  exit 0
fi

# ============ ROTA WIDGET — exige projeto @po-ui ============
if ! is_fluig_project "$CWD"; then
  exit 0
fi

# 1. Prettier — auto-fix silencioso (não bloqueia)
if command -v npx &>/dev/null; then
  npx --no-install prettier --write "$FILE_PATH" &>/dev/null || true
fi

# 2. ESLint — config do projeto; sem config, fallback para o do plugin
if command -v npx &>/dev/null; then
  ESLINT_CONFIG=$(find "$CWD" -maxdepth 4 -name node_modules -prune -o \( \
    -name "eslint.config.js" -o -name "eslint.config.mjs" -o \
    -name ".eslintrc.js" -o -name ".eslintrc.cjs" -o \
    -name ".eslintrc.json" -o -name ".eslintrc.yml" -o \
    -name ".eslintrc" \
  \) -print 2>/dev/null | head -1)
  ESLINT_ARGS=()
  if [[ -z "$ESLINT_CONFIG" && "$EXT" == "ts" && -f "$WIDGET_CONFIG" ]]; then
    ESLINT_ARGS=(--config "$WIDGET_CONFIG")
    ESLINT_CONFIG="$WIDGET_CONFIG"
  fi
  if [[ -n "$ESLINT_CONFIG" ]]; then
    ESLINT_EXIT=0
    ESLINT_OUT=$(npx --no-install eslint "${ESLINT_ARGS[@]}" "$FILE_PATH" 2>&1) || ESLINT_EXIT=$?
    if [[ $ESLINT_EXIT -ne 0 ]] && ! echo "$ESLINT_OUT" | grep -qiE "not found|command failed|could not determine"; then
      ERRORS+="ESLint:\n${ESLINT_OUT}\n"
    fi
  fi
fi

# 3. tsc --noEmit — bloqueia se error TS (só para .ts, não .spec.ts)
if [[ "$EXT" == "ts" ]] && [[ "$FILE_PATH" != *.spec.ts ]]; then
  TSCONFIG=$(find "$CWD" -maxdepth 4 -name node_modules -prune -o -name "tsconfig.json" -print 2>/dev/null | head -1)
  if [[ -n "$TSCONFIG" ]] && command -v npx &>/dev/null; then
    # --incremental: 1ª execução compila o projeto, seguintes só o que mudou —
    # tsc full a cada Write/Edit estourava o timeout de 60s em Angular real.
    # --no-install: hook não deve baixar pacote da rede; sem tsc local, pula.
    TSC_OUT=$(cd "$(dirname "$TSCONFIG")" && npx --no-install tsc --noEmit --incremental --tsBuildInfoFile .tsbuildinfo.fluig-lint 2>&1) || true
    if echo "$TSC_OUT" | grep -qE "error TS"; then
      ERRORS+="TypeScript:\n${TSC_OUT}\n"
    fi
  fi
fi

# 4. Regras Fluig para JS de widget (não aplica a spec/test)
if [[ "$EXT" == "js" ]] && \
   [[ "$FILE_PATH" != *.spec.js ]] && \
   [[ "$FILE_PATH" != *.test.js ]]; then
  if grep -q 'alert(' "$FILE_PATH" 2>/dev/null; then
    ERRORS+="Fluig: uso de alert() proibido — use Swal.fire() (SweetAlert2)\n"
  fi
fi

if [[ -n "$ERRORS" ]]; then
  jq -n --arg reason "Qualidade Fluig — corrija antes de continuar:\n\n${ERRORS}\nRegra errada para este caso? Registre: /fluig:feedback" \
    '{"decision":"block","reason":$reason}'
  exit 0
fi

exit 0
