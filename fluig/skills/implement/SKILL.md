---
name: implement
description: Orquestra Agent Team para executar plano Fluig — fluig-implementer (sonnet) implementa em worktree isolado, fluig-spec-reviewer (sonnet) verifica spec, fluig-reviewer (sonnet) revisa qualidade. Comunicação bidirecional entre teammates. Próximo passo obrigatório: /fluig:deploy.
disable-model-invocation: true
---

Você vai orquestrar a execução do plano de implementação Fluig através de um **Agent Team** com comunicação bidirecional.

## HARD GATE

Não proceda se:
1. O plano de implementação NÃO foi criado em `/fluig:plan`
2. O plano NÃO foi lido e aprovado

Se algum desses pontos faltar, peça ao usuário para primeiro executar `/fluig:plan`.

## Passo 0 — Retomar, se houver estado

Leia `docs/fluig/plans/<slug>.gates.json` antes de criar qualquer time. Estágios de
execução na ordem: `tests_unit` (duas metades) → `lint` → `spec_review` →
`code_review` → `deploy` → `qa_e2e`. Entre no primeiro estágio não-`ok` e diga ao dev
o que já passou. Sem `.gates.json` → recomende `/fluig:plan`.

## Pré-requisitos

- **Agent Teams** habilitado: `export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`
- **Claude Code v2.1.32+**
- Plano aprovado em `docs/fluig/plans/`

Se Agent Teams não estiver habilitado, informe o usuário e caia no fallback (subagents unidirecionais).

## Regra de Modelos (OBRIGATÓRIA)

| Papel | Modelo | Uso |
|-------|--------|-----|
| fluig-implementer | **sonnet** | Implementação — exige raciocínio sobre regra de negócio |
| fluig-spec-reviewer | **sonnet** | Verificação de conformidade com spec |
| fluig-reviewer | **sonnet** | Qualidade de código Fluig |
| Opus | **só no brainstorm** | O design já foi feito em opus (`/fluig:brainstorm`). Nenhum teammate escala para opus por conta própria |
| Haiku | **não usar aqui** | Haiku só em deploy (`fluig-deployer`) |


## Artefato de estado dos gates (gates.json)

Todo veredito de gate é GRAVADO em `docs/fluig/plans/<slug>.gates.json` (o slug é o basename, sem `.md`, do plano
salvo pelo `/fluig:plan`) — a skill seguinte LÊ o arquivo em vez de confiar na
memória da conversa (doc oficial: "hooks/artefatos são determinísticos; instruções
são consultivas"). Esquema único — toda chave é objeto com `status`:

```json
{
  "slug": "2026-07-12-aprovacao-desconto",
  "plan": { "status": "ok", "file": "docs/fluig/plans/2026-07-12-aprovacao-desconto.md" },
  "tests_unit": {
    "widget": { "status": "ok", "coverage_lines": 84.2, "report": "coverage/coverage-summary.json" },
    "server": { "status": "ok", "failures": 0, "junit": "logs/fluig-unit.xml" }
  },
  "lint": { "status": "ok" },
  "spec_review": { "status": "ok" },
  "code_review": { "status": "ok" },
  "deploy": { "status": "ok", "servidor": "https://fluig-hml.cliente.com.br" },
  "qa_e2e": { "status": "ok", "cenarios": 5, "junit": "logs/fluig-e2e.xml" }
}
```

`tests_unit` tem **duas metades**: `widget` (runner Angular) e `server` (harness Node
para datasets/eventos). Feature sem artefato de um dos lados grava
`{ "status": "n/a" }` naquela metade — `n/a` explícito, nunca chave ausente.

Atualize a chave correspondente ao concluir cada estágio. Pipeline vira retomável:
sessão nova lê o arquivo e continua de onde parou.

## Estágio 0 — Criar Agent Team

Crie o time de implementação:

```
TeamCreate({
  name: "fluig-impl-team",
  description: "Time de implementação Fluig com feedback bidirecional"
})
```

Os teammates serão despachados via Agent tool com:
- `subagent_type: "fluig:fluig-implementer"` (sonnet)
- `subagent_type: "fluig:fluig-spec-reviewer"` (sonnet)
- `subagent_type: "fluig:fluig-reviewer"` (sonnet)
- `isolation: "worktree"` para implementador (trabalha em cópia isolada)

## Passo 1 — Ler plano e extrair tasks

Solicite ao usuário o caminho para o plano (ex: `docs/fluig/plans/YYYY-MM-DD-<funcionalidade>.md`).

Leia o arquivo e extraia:
- **Lista completa de tasks** (com checkbox syntax)
- **Cada task:** descrição, arquivos, ciclo TDD, comandos, mensagem de commit esperada
- **Dependências entre tasks** (qual executa antes)

## Passo 2 — Loop por task

Para cada task na ordem de dependência:

### 2a. Dispatch para fluig-implementer (sonnet, worktree isolado)

```
Agent({
  subagent_type: "fluig:fluig-implementer",
  name: "impl-task-N",
  isolation: "worktree",
  model: "sonnet",
  prompt: "<conteúdo de implementer-prompt.md preenchido>"
})
```

Tasks independentes podem rodar em paralelo (múltiplos Agent calls no mesmo bloco).

Aguarde resposta. Possíveis status:
- **DONE** — task implementada, testes passam
- **NEEDS_CONTEXT** — responda via SendMessage com informação solicitada
- **BLOCKED** — investigue, forneça contexto ou escale ao usuário

### 2a-gate. Testes e cobertura (executado pelo ORQUESTRADOR)

Antes de despachar reviews, **você mesmo** valida (self-report do implementer NÃO
aprova). São **duas metades** — rode a(s) que a task tocou:

**Widget** (task mexeu em `.ts`/workspace Angular):

```bash
npm test -- --watch=false --browsers=ChromeHeadless --code-coverage
```

- Verde é o critério mecânico (com `skills/test/assets/karma.conf.template.js`,
  cobertura global < 70% já FALHA aqui — se o projeto não tem o check, copie o
  template; projeto no builder novo usa `coverageThresholds` do `angular.json`).
- Leia `coverage/coverage-summary.json`, registre o % real e grave
  `tests_unit.widget` no `.gates.json`.

**Server-side** (task mexeu em `ds_*`, `wf_*`, `events/`):

```bash
mkdir -p logs
node --test --test-reporter=junit --test-reporter-destination=logs/fluig-unit.xml \
     --experimental-test-coverage --test-coverage-lines=70 \
     --test-coverage-include='**/ds_*.js' --test-coverage-include='**/wf_*.js' \
     --test-coverage-include='**/events/**' 'testes/**/*.test.js'
```

- Critério mecânico: exit 0 **e** `fail 0` no `logs/fluig-unit.xml` — **e** todo
  `ds_*`/`wf_*`/evento tocado pela task tem arquivo de teste correspondente
  (cobertura não enxerga arquivo que nenhum teste carrega: fonte sem teste passa
  o threshold em silêncio — confira a existência um a um). Grave
  `tests_unit.server` no `.gates.json`.
- Harness e armadilhas (filename absoluto, `deepEqual`, globs desancorados,
  `mkdir -p logs`): ver a seção server-side de `/fluig:test`.

Metade sem artefato na feature: grave `{ "status": "n/a" }` — explícito, nunca omitido.
Vermelho em qualquer metade → devolva ao implementer com a saída; **máximo de 3
ciclos** de correção — no 3º vermelho, pare e reporte ao dev com o histórico.

### 2b. Dispatch para fluig-spec-reviewer (sonnet)

```
Agent({
  subagent_type: "fluig:fluig-spec-reviewer",
  name: "spec-review",
  model: "sonnet",
  prompt: "<conteúdo de spec-reviewer-prompt.md preenchido>"
})
```

**Se NÃO CONFORME:**
1. Envie feedback ao implementador via SendMessage com as divergências
2. Após correção, repita o review spec
3. Itere até **CONFORME**

### 2c. Dispatch para fluig-reviewer (sonnet)

```
Agent({
  subagent_type: "fluig:fluig-reviewer",
  name: "code-review",
  model: "sonnet",
  prompt: "<conteúdo de code-reviewer-prompt.md preenchido>"
})
```

**Se CRÍTICO:**
1. Envie feedback direto ao implementador via SendMessage
2. Após correção, re-revise
3. Itere até **APROVADO**

### 2d. Marcar task completa

```
- [x] Task [N]: [descrição] ✅
```

## Passo 3 — Merge Worktree + Encerramento

Se o implementador usou worktree isolado:
1. Revise as mudanças do worktree branch
2. Merge no branch principal do projeto
3. Limpe o worktree

Quando todas as tasks estiverem ✅:

### 3a. Lint gate global (máquina antes do LLM)

Rode o ESLint sobre **todos** os artefatos da feature, com os configs do plugin
quando o projeto não tiver os seus:

```bash
# server-side (ds_*, wf_*, events/)
npx eslint --config ${CLAUDE_PLUGIN_ROOT}/skills/test/assets/eslint.server.config.mjs <arquivos ds_/wf_/events>
# widget (se o projeto não tem eslint próprio)
npx eslint --config ${CLAUDE_PLUGIN_ROOT}/skills/test/assets/eslint.widget.config.mjs <arquivos .ts>
```

Critério mecânico: exit 0 nos dois. Grave `lint` no `.gates.json`. Erro → devolva ao
implementer (mesmo teto de 3 ciclos). Supressão (`eslint-disable`) só com justificativa
na mesma linha — e o reviewer reporta mesmo suprimido.

### 3b. Validação final global

Dispatch `fluig-reviewer` para validação de todos os artefatos juntos.

### 3c. Anunciar conclusão

```
Implementação concluída

Resultado:
- [N] tasks executadas
- [N] commits criados
- [X]% cobertura de testes
- Todos os artefatos aprovados
- Worktree: merged e limpo

Próximo passo: /fluig:deploy
```

## RED FLAGS (nunca ignore)

- **Nunca skip reviews** — implementação sempre passa por spec-reviewer E code-reviewer
- **Nunca prossiga com itens CRÍTICOS** — espere correção ou escale ao usuário
- **Nunca ignore falhas de teste** — 100% testes passam antes de review
- **Nunca escale de modelo por conta própria** — implementação e review são sonnet; decisão de design volta ao `/fluig:brainstorm` (opus), com o dev

## Fallback (sem Agent Teams)

Se Agent Teams não estiver disponível:
- Despache via Agent tool sem TeamCreate
- Comunicação unidirecional (sem SendMessage de volta)
- Mesmo fluxo de estágios, mas sem feedback bidirecional

---

## Templates de dispatch

Veja os arquivos:
- `skills/implement/implementer-prompt.md` — template para o implementer (sonnet)
- `skills/implement/spec-reviewer-prompt.md` — template para sonnet validação spec
- `skills/implement/code-reviewer-prompt.md` — template para sonnet validação código

## Consulta de Conhecimento

```
searchKnowledge({ keyword: "<termo relevante>" })
```
