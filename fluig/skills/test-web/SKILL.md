---
name: test-web
description: Ciclo completo de testes E2E do TOTVS Fluig via Playwright com evidências e documentação. Cobre roteiro → aprovação → execução com screenshots → validação → error handling (log do servidor) → specs de regressão com JUnit. Use quando precisar testar widget, formulário, dataset publicado ou processo BPM no servidor Fluig real, coletar evidências ou gerar documentação de testes.
---

# Fluig Test Web — Testes E2E com Evidências e Gate Mecânico

Ciclo completo de testes E2E contra o servidor Fluig real, em **dois modos**:

- **Modo exploratório (evidência):** MCP Playwright interativo — roteiro aprovado,
  screenshot por passo, validação com critério verificável. É onde um cenário novo
  nasce e é validado.
- **Modo gate (regressão):** specs `@playwright/test` versionadas, geradas a partir da
  sessão exploratória **já validada**, executadas com `--reporter=junit`. Exit code é o
  critério — sem LLM no loop. É o que o `/fluig:qa` consome como gate.

O Fluig é aplicação web comum (ao contrário do webapp Protheus): autenticação via
`storageState`, seletores DOM normais. Prefira seletores estáveis; screenshots são a
evidência, não o mecanismo de localização.

## Pré-requisitos

- Plugin MCP Playwright instalado (`/plugin` → instalar `playwright`)
- URL do servidor Fluig real (a proibição de `localhost` barra mock/porta morta — o sandbox real do `/fluig:base` vale) — do CLAUDE.md do projeto ou do dev
- Credenciais via `FLUIG_USER` / `FLUIG_PASSWORD` (nunca hardcoded)
- Artefato **publicado** no servidor (`/fluig:deploy` concluído — confira o
  `.gates.json`)
- Página onde o widget/form está publicado (ex.: `/portal/p/home`)

## Etapa 1 — Roteiro de testes (obrigatório, ANTES de executar)

Consulte a base antes de elaborar:

```
searchKnowledge({ platform: "fluig", skill: "fluig-test", keyword: "<funcionalidade>" })
ragSearchKnowledge({ query: "cenários de teste para <artefato> no Fluig" })
```

Formato do roteiro a apresentar ao team leader:

```markdown
# Roteiro de Teste: <nome>

**Artefato(s):** <wg_/ds_/wf_/form + nomes>
**Servidor:** <URL>
**Página:** <caminho no portal>
**Data:** <data>

## Objetivo
<o que está sendo testado e por quê>

## Pré-condições
<dados necessários, processo iniciado, permissões do usuário de teste>

## Cenários

### TC01 — <descrição>
- **Ação:** <o que fazer>
- **Dados:** <valores>
- **Resultado esperado:** <o que deve acontecer>
- **Critério VERIFICÁVEL:** <texto literal esperado no snapshot (ex.: "Solicitação
  1234 criada"), registro consultável no dataset, ou mensagem exata de bloqueio.
  PASSOU exige o critério ENCONTRADO — "a tela parece certa" NÃO é critério>

## Cleanup
<como reverter os dados>
```

**REGRA:** só executar após aprovação explícita do team leader.

## Etapa 2 — Evidências

```
evidencias/<plan-id>/
└── YYYY-MM-DD_<artefato>_<descricao>/
    ├── 01_login.png
    ├── 02_pagina_widget.png
    ├── ...
    └── relatorio.md
```

## Etapa 3 — Execução (modo exploratório)

Screenshot via `browser_take_screenshot` em **cada passo** — sem evidência não há
teste válido.

1. `browser_navigate` → URL do servidor; login com `FLUIG_USER`/`FLUIG_PASSWORD`
   (se SSO/Identity, siga o fluxo real e registre qual é) — **Screenshot:** `01_login.png`
2. Navegue até a página do artefato — **Screenshot:** `02_pagina_widget.png`
3. **Formulário dentro de processo:** abra a tarefa pela Central de Tarefas. Atenção:
   o form pode renderizar em **iframe** — se o snapshot não mostrar os campos, procure
   o frame antes de concluir que a tela não carregou.
4. Execute a ação do TC (preencher, enviar, movimentar atividade) — screenshot a cada
   preenchimento relevante.
5. **Validação:** procure o **critério verificável literal** no snapshot —
   **Screenshot:** `0N_resultado.png`. Registre PASSOU / FALHOU / BLOQUEADO.
6. **Cleanup:** reverta dados criados — screenshot final.

## Etapa 4 — Tratamento de erros (log do servidor)

Erro na tela (mensagem genérica, tela branca, HTTP 5xx) durante o teste:

1. **Screenshot imediato** do estado da tela
2. Colete o log do servidor Fluig no período do teste (Docker:
   `docker logs --since <inicio> <container-fluig>`; ver `/fluig:debug` para o setup
   do projeto) e recorte o stacktrace
3. Classifique: erro de ambiente (config/permissão), erro de artefato (dev), erro de dados
4. **Devolva ao desenvolvedor** com screenshot + stacktrace + análise + sugestão
5. **NÃO prossiga** até o erro ser resolvido; registre a lição via `/fluig:feedback`

Erro no log do servidor durante o teste é risco **ALTO por definição** na lista
fechada do `/fluig:qa` — não rebaixe.

## Etapa 5 — Review das evidências

Apresente ao team leader: lista de screenshots, resultado por cenário
(PASSOU/FALHOU com o critério encontrado/não encontrado), erros com stacktrace.

## Etapa 6 — Modo gate: spec de regressão

Cenário validado no exploratório vira spec versionada — a sessão valida com
evidência; o spec vira regressão determinística:

```bash
mkdir -p logs
PLAYWRIGHT_JUNIT_OUTPUT_NAME=logs/fluig-e2e.xml npx playwright test e2e/<artefato>.spec.ts --reporter=junit
```

- Autenticação via `storageState` (setup project) — nunca login por spec.
- Cada `expect` do spec é o critério verificável do TC correspondente — mesma
  fonte, dois consumidores.
- Critério mecânico: exit 0. Grave `qa_e2e` no `.gates.json` com o caminho do XML.
- Specs vivem no repo do projeto (`e2e/`), rodam em CI e no `/fluig:qa` das
  próximas demandas.

**A spec versionada É a persistência do cenário.** O roteiro aprovado e as evidências
ficam em `evidencias/<plan-id>/`, junto do repositório do projeto — é o que a próxima
demanda lê.

## Etapa 7 — Documentação e lições

- Falha, armadilha ou lição aprendida durante o teste → registre via `/fluig:feedback`
  (que submete à base de conhecimento com sua aprovação).
- Documentação formal (quando o cliente exigir): relatório em Markdown/DOCX com
  screenshots inline, resultado esperado × obtido por cenário e conclusão
  APROVADO/REPROVADO.

## Regras críticas

- **Aprovação do roteiro antes de executar** — sem exceção.
- **Screenshot em cada passo** — sem evidência não há teste válido.
- **Critério verificável literal** — "parece certo" não é critério.
- **Nunca credencial hardcoded. `localhost` só se for o sandbox real do `/fluig:base`.**
- Snapshot sem os campos esperados: verifique **iframe** e tempo de carregamento
  antes de reportar falha.
- Dialogs/toasts (Swal): verifique antes de interagir com a tela.
