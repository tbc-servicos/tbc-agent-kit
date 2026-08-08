---
name: qa
description: Testes de integração e E2E (Playwright) contra servidor Fluig deployado. Roda as specs E2E (JUnit) ou aciona fluig:test-web, e o fluig-qa teammate. Se riscos ALTOS encontrados, retorna para /fluig:implement. Acione após /fluig:deploy. Próximo passo: /fluig:verify.
disable-model-invocation: true
---

Você vai conduzir testes de integração e QA contra os artefatos deployados no servidor Fluig.

## HARD GATE

- **Leia `docs/fluig/plans/<slug>.gates.json`** e confirme: `deploy.status=ok`,
  `tests_unit.widget.status` e `tests_unit.server.status` ∈ {ok, n/a}, `lint.status=ok`.
  Não confie em afirmação da conversa — o arquivo é a fonte de verdade (pipeline retomável). O `<slug>` é o basename (sem `.md`) do plano salvo pelo `/fluig:plan` em `docs/fluig/plans/`; havendo mais de um `.gates.json`, pergunte ao dev qual feature.

Não inicie testes de QA se:
- O deploy não foi realizado com sucesso (não há servidor com os artefatos)
- O servidor não está acessível ou os artefatos não estão publicados

Verifique que o deploy do Passo 3 anterior foi concluído antes de prosseguir.

## Passo 1 — Executar testes E2E (Playwright)

Primeiro, **liste os artefatos da task** (do plano) e confira, um a um, qual spec em
`e2e/` cobre cada um. Spec de demanda anterior não conta como cobertura da task atual.

**1a. Existe spec cobrindo CADA artefato da task** — rode o gate mecânico:

```bash
mkdir -p logs
PLAYWRIGHT_JUNIT_OUTPUT_NAME=logs/fluig-e2e.xml npx playwright test --reporter=junit
```

Critério: exit 0. Leia o XML (não aceite afirmação da conversa), grave `qa_e2e` no
`.gates.json` com o caminho do relatório. Falha → screenshot + log do servidor, e
volta ao `/fluig:implement`.

**1b. Algum artefato da task SEM spec** — **PARE e acione `/fluig:test-web`** para
esses artefatos (roteiro aprovado → execução com evidências → spec de regressão
gerado da sessão validada), e só então rode o 1a. QA sem E2E **dos artefatos da
task** é reprovação automática, não aprovação vazia — suíte antiga verde não aprova
artefato novo.

Use FLUIG_BASE_URL apontando para o servidor real (homologação ou sandbox do `/fluig:base` — nunca mock/porta morta).

Os testes E2E devem validar:
- Carregamento dos formulários e datasets no servidor real
- Integração com Protheus (se aplicável)
- Fluxo completo do usuário contra a API Fluig live

**Se os testes E2E falharem:** corrija o artefato, redeploy via `/fluig:deploy` e retorne para este passo.

## Passo 2 — Acionar fluig-qa para análise de qualidade

Após testes E2E passando, acione o agente `fluig-qa` via SendMessage (model: sonnet):

```
Analise a qualidade dos artefatos [listar nomes] publicados em [URL servidor].
Verifique: casos de borda não tratados, campos obrigatórios sem validação,
datasets sem constraints de filtro, cobertura de testes em widgets, e estado de erro.
Classifique riscos como ALTO, MÉDIO ou BAIXO.
```

O agente `fluig-qa` acessa o servidor real para validar comportamento e identificar:
- Validações faltantes
- Tratamento de erros inadequado
- Cenários de borda expostos
- Cobertura de testes insuficiente

## Passo 3 — Avaliar resultados

Revise a análise do fluig-qa.

### Lista FECHADA de risco ALTO

Qualquer item abaixo é **ALTO por definição** — nada desta lista pode ser rebaixado
por "parece ok", "cenário improvável" ou impressão visual:

1. Caso de teste E2E cujo critério verificável **não foi encontrado** na tela/snapshot
2. Erro no log do servidor Fluig durante a execução dos testes (stacktrace, HTTP 5xx)
3. Dataset devolvendo linha de erro estruturada (ou exceção) em cenário **feliz**
4. SQL/constraint montado por concatenação de entrada do usuário em código novo
5. Campo obrigatório do formulário gravando vazio sem validação
6. Qualquer gate anterior vermelho ou ausente no `.gates.json`

Fora da lista, classifique MÉDIO/BAIXO por julgamento — mas a lista acima não se julga.

### Se houver riscos ALTO:

```
Riscos ALTOS encontrados na análise de QA:
[listar riscos]

Estes precisam ser corrigidos antes de prosseguir para produção.
Retorne para /fluig:implement para correção, depois redeploy via /fluig:deploy.
```

Não avance para `/fluig:verify` até riscos ALTOS serem resolvidos.

### Se houver apenas riscos MÉDIO/BAIXO:

Apresente os resultados ao usuário e prossiga para o próximo passo.

## Passo 4 — Anunciar conclusão

```
QA concluído.

Testes E2E: [PASSANDO] — [N] cenários
Análise de qualidade: [APROVADO / APROVADO COM RESSALVAS]

Riscos identificados:
- Altos: N
- Médios: N
- Baixos: N

Próximo passo: /fluig:verify
```

## Regras obrigatórias

- Testes E2E sempre contra servidor real (homologação ou sandbox do `/fluig:base` — nunca mock/porta morta)
- Fluig-qa sempre executado após E2E (análise no servidor live)
- Riscos ALTOS obrigam retorno para `/fluig:implement` — não pule
- Riscos MÉDIO/BAIXO são documentados mas não bloqueiam
- O próximo passo obrigatório é `/fluig:verify` — gate final antes de produção

---

## Consulta de Conhecimento

Se precisar de informação não disponível no MCP, consulte o RAG:
```
searchKnowledge({ keyword: "<termo relevante>" })
```
