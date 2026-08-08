---
name: plan
description: Decompõe o design aprovado do brainstorm em tasks concretas para teammates ADVPL. Gera plano tipado com artefatos R[MOD][TYPE][SEQ].prw/.tlpp, gates de lint e testes E2E Playwright (test-web). Use após /protheus:brainstorm.
disable-model-invocation: true
---

## Instruções para Claude

Derive a feature ativa dos `docs/plans/*.gates.json` — do arquivo, nunca da memória
da conversa. Se não houver `.gates.json` nem design doc, recomende
`/protheus:brainstorm` primeiro.

---

## Passo 1 — Ler o design aprovado

Liste os `docs/plans/*.gates.json` e derive o estágio de cada feature **do arquivo**:

| Estado observado no `.gates.json` | Estágio | Próximo passo |
|---|---|---|
| `design.status != "aprovado"` | design em aberto | volte ao `/protheus:brainstorm` |
| `design` aprovado, `plan.status = "pendente"` | pronto para planejar | siga este skill |
| `plan.status = "ok"`, gates de execução ausentes | plano pronto | `/protheus:implement` |
| gates de execução parciais | implementação em andamento | `/protheus:implement` (retoma) |

Se houver **mais de uma** feature com `design` aprovado e `plan` pendente, liste-as
numeradas com data e slug e **pergunte qual planejar**. Nunca escolha a mais recente
por conta própria: o dev pode estar voltando a uma feature da semana passada, e
planejar a errada só aparece no review — depois de o implementer já ter escrito código.

Design doc antigo sem `.gates.json` (anterior a esta versão): confirme com o dev qual
arquivo usar antes de seguir.

Leia o design doc da feature escolhida. Extraia:
- Lista de artefatos a implementar (nome do arquivo, tipo, responsabilidade)
- Módulo Protheus (FAT, FIN, EST, COM, RH…)
- Tabelas envolvidas
- Regras de negócio críticas

---

## Passo 2 — Decompor em tasks de implementação

Para cada artefato identificado no design, crie uma task com:

```
Task N: Implementar [NOME_ARQUIVO]
Teammate: protheus-implementer (sonnet)
Artefato: R[MOD][TYPE][SEQ].prw (ou .tlpp)
Tipo: [User Function | MVC | Ponto de Entrada | Relatório]
Responsabilidade: [descrição funcional]
Contexto para o teammate:
  - Design doc: docs/plans/[arquivo].md
  - Tabelas: [lista]
  - Regras: [lista]
  - Padrões: consultar MCP para convenções atualizadas
```

Tasks de implementação **podem rodar em paralelo** quando os artefatos
forem independentes (PE em arquivo próprio, funções sem dependência mútua).

### Fechar a lista de fontes (orçamento de arquivos)

A lista de fontes do plano é **fechada**: o implementer não cria fonte que não esteja na
tabela de tasks. Fonte novo = volta ao plano (e, se for decisão de design, ao
`/protheus:brainstorm`).

| Tamanho do desenvolvimento | Orçamento de fontes (fora os de teste) |
|---|---|
| Ajuste pontual / PE | 1 |
| Rotina nova média | até 3 |
| Desenvolvimento grande | 1 fonte por camada por contexto — acima disso, justifique no plano |

- **Camada ≠ arquivo.** TLPP aceita mais de uma classe no mesmo fonte; classes coesas do mesmo
  papel e contexto ficam juntas, e só se separam quando mudam por motivos diferentes.
- **Teto:** fonte acima de ~800 linhas (ou classe de ~500) é sinal de divisão real.
- Sobre-engenharia é dívida igual a monólito: **os dois** custam manutenção e patch.

---

## Passo 3 — Adicionar tasks fixas de qualidade (sempre nesta ordem)

Após todas as tasks de implementação, adicione obrigatoriamente:

### Task Review Spec Compliance
```
Task N+1: Review spec compliance
Teammate: protheus-spec-reviewer (sonnet)
Escopo: todos os artefatos implementados
Critério de aprovação: ✅ SPEC OK em todos os artefatos
Bloqueio: tasks de implementação devem estar concluídas
```

### Task Review Qualidade
```
Task N+2: Review qualidade de código
Teammate: protheus-reviewer (sonnet)
Escopo: todos os artefatos aprovados no spec compliance
Critério de aprovação: Aprovado para compilação: SIM
Bloqueio: spec compliance aprovado
```

### Task Lint Gate
```
Task N+3: Lint local (advpls appre)
Ação: rodar advpls appre em todos os artefatos
GATE: se lint retornar erros tipo "0" → fluxo para aqui
Critério de aprovação: zero erros tipo "0"
Bloqueio: ambos os reviews aprovados
```

### Task Deploy (compilação + patch)
```
Task N+4: Compilar e gerar patch
Skill: /protheus:deploy
Ação: compilar no AppServer via advpls cli, gerar patch .ptm
Bloqueio: lint aprovado
```

### Task Testes E2E Playwright

> **Engine oficial de E2E: Playwright** (`/protheus:test-web`) — visão computacional real
> (screenshots + snapshot da tela). **O TIR não é a forma oficial de testar** (não tem visão
> computacional): use-o apenas, opcionalmente, como suíte de regressão CI gerada a partir da
> sessão Playwright já validada (ver nota em `/protheus:qa`).
```
Task N+5: Executar testes E2E Playwright (via /protheus:qa → /protheus:test-web)
Skill: /protheus:qa
Escopo: fluxos críticos de negócio identificados no design
Bloqueio: compilação bem-sucedida (RPO atualizado)
```

---

## Passo 3.5 — Regressão: o que não pode quebrar

Toda customização Protheus mexe em terreno compartilhado: um PE roda dentro de rotina
TOTVS que outras customizações também usam; um campo `X_` novo entra em tabela que a
rotina padrão grava; um ExecAuto muda o que rotinas a jusante leem.

### Alcance medido — o que o plano não previu

Rode esta medição **antes de escrever o arquivo de regressão** — se a resposta for
REDESENHA, nenhum arquivo órfão fica para trás. Varra os callers e **confronte a
varredura com a lista fechada de fontes do Passo 2**, separando o que ela atinge
fora dela.

Para cada função, PE ou campo que a demanda altera:

```bash
grep -rn "U_<Funcao>\|<PE>\|<CAMPO>" --include="*.prw" --include="*.tlpp" .
```

Referência que cai em fonte **fora da lista do plano** é alcance não previsto. Antes de
salvar o plano, apresente ao dev e espere resposta:

> Alcance medido de **<feature>**:
> - Fontes no plano: `<lista>`
> - Atingidos fora do plano: `<arquivo:linha — quem usa>` (ou "nenhum")
>
> 1. **SEGUE** — cada atingido vira item na tabela de regressão abaixo
> 2. **REDESENHA** — o alcance mostra que a demanda é maior que o desenhado; volta ao
>    `/protheus:brainstorm`

Se a varredura não for possível (o caller está em fonte padrão TOTVS que não está no
repo), diga isso com todas as letras: "alcance não medido" é informação. Silêncio vira
"não tem impacto", que é a frase que costuma preceder o incidente.

Antes de salvar o plano, escreva `docs/legado/regressao/<slug>.md` — um item por
comportamento que **existia antes** e precisa continuar existindo depois.

Fonte dos itens, nesta ordem:
1. Regras CONFIRMADO de `docs/legado/<fatia>.md` (se o mapa da `/protheus:arqueologia`
   existir) que a demanda toca de raspão
2. Comportamento de PE que outras rotinas dependem
3. Campo de tabela padrão que outra rotina TOTVS também grava
4. Retorno de função com caller fora da demanda (`grep -rn "U_<Funcao>"`)

| ID | Origem (`arquivo:linha` ou `RN-<MOD>-NN`) | O que precisa continuar verdadeiro | Como verificar | Sinal de violação |
|---|---|---|---|---|
| W001 | `RFATA001.prw:210` (`RN-FAT-03`) | Pedido sem transportadora continua gravando com frete zero | cenário E2E `W001` no plano de QA (`/protheus:qa` → `/protheus:test-web`) | pedido sem transportadora passa a bloquear a gravação |

Regras:
- **Só entra item CONFIRMADO.** Comportamento INFERIDO ou LACUNA vai para uma seção
  "Observações", sem peso de regressão — vigiar o que você não confirmou produz alarme
  falso, e alarme falso mata o arquivo em duas demandas.
- **IDs são estáveis e append-only.** Item que deixou de valer não é apagado: vai para
  a seção "Arquivadas" **com o motivo e a data** — o motivo é o que impede a próxima
  demanda de reintroduzir o problema que esta resolveu.
- **Todo item verificável vira cenário E2E no plano de QA** — o `W001` entra no escopo
  da task de testes E2E do Passo 3, nomeado pelo ID, e é lá que ele é exercido. Item
  que só dá para conferir lendo o fonte entra como **inspeção nomeada** (`arquivo:linha`
  a conferir no `/protheus:verify`). Item sem forma de verificar é observação, não item
  de regressão.

Esta lista cobre só o que **existia antes**. O comportamento que esta demanda
**criar** entra na mesma lista no Passo 2.5 do `/protheus:verify`, depois do E2E.

Na demanda seguinte que tocar a mesma fatia, o `/protheus:brainstorm` lê este arquivo
no Passo 1 e cada item vira **restrição** do design — não sugestão.

---

## Passo 4 — Salvar o plano

Salve o plano completo em:

```
docs/plans/YYYY-MM-DD-[modulo]-[descricao]-plan.md
```

E atualize o `.gates.json` da feature:
`"plan": { "status": "ok", "file": "docs/plans/<arquivo>-plan.md" }`

Formato do plano:

```markdown
# Plano: [Descrição]

**Design:** docs/plans/[design-doc].md
**Módulo:** [MOD]
**Data:** YYYY-MM-DD
**Regressão:** docs/legado/regressao/[slug].md (ou "não se aplica — justificativa")

## Tasks de Implementação

| # | Artefato | Tipo | Teammate | Paralelo? |
|---|---------|------|----------|-----------|
| 1 | RFATA001.prw | User Function | protheus-implementer (sonnet) | sim |
| 2 | PE_MATA010.prw | Ponto de Entrada MVC | protheus-implementer (sonnet) | sim |

## Tasks de Qualidade e Deploy

| # | Task | Teammate/Skill | Bloqueada por |
|---|------|----------------|--------------|
| 3 | Spec compliance | protheus-spec-reviewer (sonnet) | 1, 2 |
| 4 | Qualidade código | protheus-reviewer (sonnet) | 3 |
| 5 | Lint gate (appre) | — | 4 |
| 6 | Compilação + patch | /protheus:deploy | 5 |
| 7 | Testes E2E Playwright | /protheus:qa | 6 |
```

---

## Passo 5 — Encadear implementação

Após salvar o plano:

```
Plano salvo em docs/plans/[arquivo]-plan.md

Próximo passo:
  /protheus:implement
```

---

## Consulta de Conhecimento

Se precisar de informação não disponível no MCP, consulte o RAG:
```
searchKnowledge({ keyword: "<termo relevante>" })
```

## Rastreabilidade task → verificação → evidência

- Numere as tasks com ID estável (`T1`, `T2`, …) no plano.
- Cada cenário E2E referencia o ID da task ou do item de regressão que exercita
  (`T1: …`, `W001: …`), para o `/protheus:verify` conseguir dar veredito item a item.
- Evidências E2E ficam em `evidencias/<plan-id>/`.
