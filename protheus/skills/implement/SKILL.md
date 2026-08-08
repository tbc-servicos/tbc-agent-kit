---
name: implement
description: Orquestra Agent Team para executar o plano ADVPL/TLPP — protheus-implementer (sonnet) implementa em worktree isolado, protheus-spec-reviewer (sonnet) verifica spec, protheus-reviewer (sonnet) revisa qualidade. Comunicação bidirecional entre teammates. Gate de compilação via lint. Use após /protheus:plan. Próximo passo: /protheus:deploy.
disable-model-invocation: true
---

## Instruções para Claude

Leia o plano da feature ativa (ver Passo 0). Se não houver plano, recomende
`/protheus:plan` primeiro.

---

## Passo 0 — Retomar, se houver estado

Leia `docs/plans/<slug>.gates.json` **antes de criar qualquer time**. O estágio vem
do arquivo, nunca da memória da conversa. A varredura de retomada olha **só os
estágios de execução**, nesta ordem: `spec_review` → `code_review` → `lint` →
`deploy` → `qa_e2e` (`design` e `plan` ficam fora — têm vocabulário próprio):

- Arquivo com `plan.status = "ok"` e sem estágio de execução gravado → comece do
  Estágio 0.
- Estágios de execução parciais (ex.: `spec_review.status = "ok"`, `code_review`
  ausente) → entre no primeiro estágio de execução cuja chave ainda não está
  `"status": "ok"`, e diga ao dev o que já passou e de onde vai continuar.
- Mais de um `.gates.json` com `plan.status = "ok"` e execução incompleta → liste e
  pergunte qual retomar.
- Sem `.gates.json` → recomende `/protheus:plan`.

---

## Pré-requisitos

- **Agent Teams** habilitado: `export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`
- **Claude Code v2.1.32+**
- Plano aprovado em `docs/plans/`

Se Agent Teams não estiver habilitado, informe o usuário e caia no fallback (Estágio 1-alt).

---

## Regra de Modelos (OBRIGATÓRIA)

| Papel | Modelo | Uso |
|-------|--------|-----|
| protheus-implementer | **sonnet** | Implementação — exige raciocínio sobre regra de negócio |
| protheus-spec-reviewer | **sonnet** | Verificação de conformidade com spec |
| protheus-reviewer | **sonnet** | Qualidade de código ADVPL/TLPP |
| Opus | **só no brainstorm** | O design já foi feito em opus (`/protheus:brainstorm`). Nenhum teammate escala sozinho |
| Haiku | **não usar aqui** | Haiku só em deploy/compilação (`protheus-deployer`) |

---


## Artefato de estado dos gates (gates.json)

Todo veredito de gate é GRAVADO em `docs/plans/<slug>.gates.json` — o **mesmo arquivo
que o `/protheus:brainstorm` criou** ao aprovar o design (o slug é o da feature, sem
sufixo `-plan`). Nunca crie um segundo arquivo. A skill seguinte LÊ o arquivo em vez
de confiar na memória da conversa (doc oficial: "hooks/artefatos são determinísticos;
instruções são consultivas"). Esquema único:

```json
{
  "slug": "2026-07-12-fat-desconto",
  "design": { "status": "aprovado", "doc": "docs/plans/2026-07-12-fat-desconto-design.md" },
  "plan":   { "status": "ok", "file": "docs/plans/2026-07-12-fat-desconto-plan.md" },
  "spec_review": { "status": "ok" },
  "code_review": { "status": "ok" },
  "lint": { "status": "ok" },
  "deploy": { "status": "ok", "patch": "patch_20260712.ptm" },
  "qa_e2e": { "status": "ok", "cenarios": 5 }
}
```

Regras do esquema:
- Toda chave é **objeto com `status`** — nunca string solta.
- `design` e `plan` têm vocabulário próprio (`aprovado`/`pendente`/`ok`) e ficam
  **fora** da varredura de retomada do Passo 0.
- Os estágios de **execução**, na ordem: `spec_review` → `code_review` → `lint` →
  `deploy` → `qa_e2e`. Atualize a chave ao concluir cada um.

Pipeline vira retomável: sessão nova lê o arquivo e continua de onde parou.

## Estágio 0 — Criar Agent Team

Crie o time de implementação:

```
TeamCreate({
  name: "protheus-impl-team",
  description: "Time de implementação ADVPL/TLPP com feedback bidirecional"
})
```

Os teammates serão despachados via Agent tool com:
- `subagent_type: "protheus:protheus-implementer"` (sonnet)
- `subagent_type: "protheus:protheus-spec-reviewer"` (sonnet)
- `subagent_type: "protheus:protheus-reviewer"` (sonnet)
- `isolation: "worktree"` para implementador (trabalha em cópia isolada)

---

## Estágio 1 — Implementação (teammate sonnet, worktree isolado)

Para cada task de implementação do plano, despache o teammate `protheus-implementer`:

```
Agent({
  subagent_type: "protheus:protheus-implementer",
  name: "impl-task-N",
  isolation: "worktree",
  model: "sonnet",
  prompt: "<conteúdo do implementer-prompt.md preenchido>"
})
```

Leia o template em `skills/implement/implementer-prompt.md` e preencha com:
- Texto completo da task
- Conteúdo do design doc
- Contexto adicional (tabelas, regras, dependências)

Tasks independentes podem rodar em paralelo (múltiplos Agent calls no mesmo bloco).
Tasks com dependência rodam em sequência.

### Tratamento de respostas:

- **DONE:** Avance para o Estágio 2
- **BLOCKED:** Analise o bloqueio. Se for dependência de outra task, reordene. Se for técnico, use SendMessage para fornecer contexto adicional ao implementador.
- **NEEDS_CONTEXT:** Responda a dúvida do implementador via SendMessage com contexto adicional.

### Fallback (sem Agent Teams):

Se Agent Teams não estiver disponível, use o padrão anterior:
- Despache via Agent tool sem TeamCreate
- Comunicação unidirecional (sem SendMessage de volta)

Aguarde conclusão de todas as tasks antes de avançar.

---

## Estágio 2 — Review Spec Compliance (teammate sonnet)

Despache o teammate `protheus-spec-reviewer`:

```
Agent({
  subagent_type: "protheus:protheus-spec-reviewer",
  name: "spec-review",
  model: "sonnet",
  prompt: "<conteúdo do spec-reviewer-prompt.md preenchido>"
})
```

Leia o template em `skills/implement/spec-reviewer-prompt.md` e preencha com:
- Lista de artefatos implementados (com caminhos — se worktree, usar o path do worktree)
- Design doc original
- Tasks do plano

**Critério de avanço:** ✅ SPEC OK em todos os artefatos.

**Se houver ❌ SPEC FALHA:**
1. Identifique as divergências
2. Envie feedback ao implementador via SendMessage com as divergências
3. Após correção, repita o review spec
4. Só avance quando todos os artefatos estiverem ✅

---

## Estágio 3 — Review Qualidade de Código (teammate sonnet)

Despache o teammate `protheus-reviewer`:

```
Agent({
  subagent_type: "protheus:protheus-reviewer",
  name: "code-review",
  model: "sonnet",
  prompt: "<conteúdo do code-reviewer-prompt.md preenchido>"
})
```

Leia o template em `skills/implement/code-reviewer-prompt.md` e preencha com:
- Lista de artefatos aprovados no spec review
- Contexto do projeto

**Critério de avanço:** `Aprovado para compilação: SIM`

**Se houver CRÍTICOs:**
- Envie feedback direto ao implementador via SendMessage
- Ciclo: corrige (implementer) → re-review → avança

---

## Estágio 4 — Lint Gate (validação local)

Antes de encaminhar para deploy, rode lint local em todos os artefatos:

```bash
advpls appre /caminho/arquivo.prw -I /caminho/includes/
```

**Critério de avanço:** zero erros tipo "0" no lint.

**Se houver erros:**
```
GATE DE LINT — fluxo interrompido

Erros do advpls appre:
[erros com arquivo + linha]

Ações necessárias:
1. Corrija os erros nos artefatos indicados
2. Repita os reviews (Estágios 2 e 3) se a correção for substancial
3. Reexecute o lint após correção
```

---

## Estágio 5 — Merge Worktree + Encerramento

Se o implementador usou worktree isolado:
1. Revise as mudanças do worktree branch
2. Merge no branch principal do projeto
3. Limpe o worktree

Quando todos os estágios passarem:

```
Implementação concluída

Artefatos implementados: [lista]
Spec review: ✅ todos conformes
Code review: Aprovado para compilação: SIM
Lint: PASS (0 erros)
Worktree: merged e limpo

Próximo passo: /protheus:deploy
```

### Sobre complexidade

Se durante a implementação aparecer uma decisão de **design** que o brainstorm não
resolveu (nova camada, novo fonte, contrato diferente do aprovado), **pare** — isso não se
resolve na implementação:
```
⚠️ Task [N] esbarra em decisão de design não coberta pelo design aprovado: [motivo].
Volte ao /protheus:brainstorm (opus) antes de continuar.
```

**Nunca escalar automaticamente.** A decisão é sempre do desenvolvedor.

---

## Consulta de Conhecimento

Se precisar de informação não disponível no MCP, consulte o RAG:
```
searchKnowledge({ keyword: "<termo relevante>" })
```
