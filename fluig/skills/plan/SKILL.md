---
name: plan
description: Escreve plano de implementação para artefatos Fluig. Mapeia arquivos, define tasks com TDD, e salva em docs/fluig/plans/. Acione após /fluig:brainstorm aprovar o design. Próximo passo obrigatório: /fluig:implement.
disable-model-invocation: true
---

Você vai conduzir a elaboração de um plano de implementação detalhado para artefatos Fluig. Este plano será executado pela skill `/fluig:implement` com orquestração de teammates.

## HARD GATE

Não proceda com o planejamento se o design NÃO foi aprovado no `/fluig:brainstorm`. Peça ao usuário que primeiro execute a skill de brainstorm e obtenha aprovação.

## Passo 1 — Ler spec do design e CLAUDE.md

Confirme com o usuário o caminho para:
1. **Documento de spec** produzido pelo `/fluig:brainstorm` (geralmente salvação em docs/fluig/ ou indicado pelo usuário)
2. **CLAUDE.md** do projeto (no diretório raiz do projeto)

Leia ambos os documentos para:
- Entender o design aprovado
- Identificar convenções de nomenclatura (prefixos `ds_`, `wg_`, `wf_`, etc.)
- Notar dependências entre artefatos
- Coletar URLs de servidores (integração com Protheus)

## Passo 2 — Mapear estrutura de arquivos

Com base no design, estruture a lista de **arquivos a criar ou modificar**:

### Estrutura de Arquivos

Consulte o MCP para a estrutura do artefato:

```
searchKnowledge({ platform: "fluig", skill: "<tipo do artefato>", keyword: "template" })
```

Use a estrutura retornada para mapear os arquivos a criar/modificar.

Cada arquivo deve estar totalmente qualificado com caminho relativo ao projeto.

## Passo 3 — Escrever tasks com ciclo TDD

Estruture o planejamento em **tasks** usando checkbox syntax. Cada task segue o ciclo **TDD** (Test-Driven Development):

```
- [ ] **Task 1: Criar dataset ds_meu_dataset**
  - [ ] Escrever teste unitário em `testes/ds_meu_dataset.test.js` com o harness do plugin
        (`fluig-mock.cjs` — ver seção server-side de `/fluig:test`) — falha esperada
  - [ ] Verificar que o teste falha (`node --test testes/ds_meu_dataset.test.js`)
  - [ ] Implementar `datasets/ds_meu_dataset.js` (ES5/Rhino: var e function, sem let/const)
  - [ ] Executar `node --test` — teste passa
  - [ ] Commit com mensagem: "feat(dataset): implementar ds_meu_dataset com query [resumo]"

- [ ] **Task 2: Criar widget Angular wg_meu_widget com componente principal**
  - [ ] Escrever teste unitário Jasmine em `wg_meu_widget/src/app/components/wg-meu-widget.component.spec.ts` (falha esperada)
  - [ ] Verificar que o teste falha
  - [ ] Implementar `wg_meu_widget/src/app/components/wg-meu-widget.component.ts` com template HTML
  - [ ] Executar `npm test` — teste passa
  - [ ] Commit com mensagem: "feat(widget): criar componente principal wg_meu_widget"

- [ ] **Task 3: Criar serviço de integração**
  - [ ] Escrever teste em `wg_meu_widget/src/app/services/meu-widget.service.spec.ts`
  - [ ] Implementar `wg_meu_widget/src/app/services/meu-widget.service.ts`
  - [ ] Mock de chamadas REST para dataset
  - [ ] Executar `npm test` — cobertura >= 70%
  - [ ] Commit: "feat(service): criar meu-widget.service com integração a dataset"

- [ ] **Task 4: Testes E2E do fluxo completo**
  - [ ] Escrever testes Playwright em `wg_meu_widget/e2e/wg-meu-widget.e2e.spec.ts`
  - [ ] Mock do servidor Fluig (FLUIG_BASE_URL)
  - [ ] Executar `npm run e2e`
  - [ ] Todos os cenários passando
  - [ ] Commit: "test(e2e): adicionar testes E2E para fluxo completo"
```

**Cada task deve incluir:**
- Descrição exata do que será feito
- Arquivos afetados (caminho completo)
- Ciclo TDD explícito (teste falha → implementa → passa)
- Comando exato para executar e validar (ng test, npm test, ng build, etc.)
- Mensagem de commit esperada

## Passo 3.5 — Regressão: o que não pode quebrar

Artefato Fluig vive em terreno compartilhado: o dataset que a demanda altera alimenta
outros formulários e widgets; o evento de processo roda para toda solicitação, não só
para a da demanda; o campo de formulário aparece em relatórios e integrações.

Antes de salvar o plano, escreva `docs/legado/regressao/<slug>.md` — um item por
comportamento que **existia antes** e que a demanda não pode mudar:

| ID | Origem (artefato + onde, ou `RN-<FATIA>-NN`) | O que precisa continuar verdadeiro | Como verificar | Sinal de violação |
|---|---|---|---|---|
| W001 | `ds_clientes` (constraint `ativo`) | Widget de consulta continua listando só clientes ativos | teste harness `testes/ds_clientes.test.js` | cliente inativo aparece na lista |

Regras:
- **Só entra item CONFIRMADO** (fato lido do projeto ou do ambiente — mapa da
  `/fluig:arqueologia`). INFERIDO/LACUNA vai para "Observações", sem peso de regressão.
- Cada item vira teste do harness (`node --test`), cenário de spec E2E (`e2e/`), ou
  checagem manual nomeada no `/fluig:verify`. Item sem forma de verificar é
  observação.
- **IDs estáveis e append-only.** Item que deixou de valer vai para "Arquivadas" com
  o motivo e a data — nunca apagado.
- Esta lista cobre só o que **existia antes**. O comportamento que esta demanda
  **criar** entra na mesma lista no writeback do `/fluig:verify`, depois do QA.

Adicione a linha `**Regressão:** docs/legado/regressao/<slug>.md` (ou "não se aplica —
justificativa") ao cabeçalho do plano.

## Passo 4 — Salvar plano em docs/fluig/plans/

Ao salvar o plano, grave também `docs/fluig/plans/<slug>.gates.json` (slug = basename
do plano, sem `.md`) — o estado dos gates que `/fluig:implement`, `deploy`, `qa` e
`verify` leem:

```json
{ "slug": "<slug>", "plan": { "status": "ok", "file": "docs/fluig/plans/<slug>.md" } }
```

Se já existir um `.gates.json` com este slug, atualize só a chave `plan` e preserve
as demais (sobrescrever apagaria gates de execução já conquistados).

Crie ou use o diretório `docs/fluig/plans/` no projeto. Salve o plano com nome:
```
YYYY-MM-DD-<nome-funcionalidade>.md
```

**Exemplo:** `2026-03-20-integracao-dashboard.md`

O arquivo deve conter:

```markdown
# Plano de Implementação — [Nome da Funcionalidade]

**Data:** [YYYY-MM-DD]
**Design aprovado em:** [link para spec ou resumo]
**Para execução:** use `/fluig:implement`

## Artefatos a criar/modificar

[Lista de arquivos do Passo 2]

## Tasks com ciclo TDD

[Tasks do Passo 3, com checkboxes]

## Modelo por fase

| Fase | Modelo | Razão |
|------|--------|-------|
| Brainstorm / design | opus | decisão de arquitetura — feito antes, no `/fluig:brainstorm` |
| Implementação (dev) | sonnet | implementação carrega regra de negócio, não é mecânica |
| Review + QA | sonnet | validação semântica e conformidade |
| Deploy | haiku | mecânico (upload/restart), sem decisão de código |

## Próximos passos

Após aprovação deste plano:
1. Agente `fluig-implementer` (sonnet) executa tasks 1-N
2. Agente `fluig-spec-reviewer` (sonnet) valida conformidade com spec
3. Agente `fluig-reviewer` (sonnet) valida qualidade de código
4. Resultado: `/fluig:deploy`
```

## Passo 5 — Anunciar conclusão

Após salvar o plano:

> "✅ Plano salvo em `docs/fluig/plans/YYYY-MM-DD-<funcionalidade>.md`"
>
> **Próximo passo:** `/fluig:implement` para iniciar a execução das tasks com orquestração de teammates."

Inclua o caminho exato do arquivo salvo.

## Regras obrigatórias

- Não avance sem design aprovado no `/fluig:brainstorm`
- Sempre ler CLAUDE.md para usar prefixos corretos
- Tasks devem ser granulares (não confundir tasks com passos dentro de uma task)
- TDD em cada task: teste falha → implementa → teste passa
- Caminhos de arquivo sempre qualificados (relativos ao raiz do projeto)
- Comandos sempre explícitos (ng test, npm test, ng build, etc.)
- Modelo sonnet para implementação e reviews; haiku só no deploy; opus só no brainstorm
- Plano salvo em git antes de acionar `/fluig:implement`
- **Lista de artefatos fechada:** o implementer não cria arquivo fora da lista do Passo 2.
  Arquivo novo = volta ao plano. Não crie service/camada especulativa: só extraia quando
  houver **2+ consumidores** ou a testabilidade exigir o dublê.

---

## Consulta de Conhecimento

Se precisar de informação não disponível no MCP, consulte o RAG:
```
searchKnowledge({ keyword: "<termo relevante>" })
```

## Rastreabilidade task → teste → evidência

- Numere as tasks com ID estável (`T1`, `T2`, …) no plano.
- O teste de cada task referencia o ID: `describe('T1 — …')` e commit `feat(T1): …`.
- O spec-reviewer verifica "cada task tem teste com o ID dela"; evidências E2E em
  `evidencias/<plan-id>/`.
