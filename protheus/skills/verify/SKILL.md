---
name: verify
description: Gate final antes de produção. Checklist de conformidade TOTVS (MIT043, Code Analysis, patch .ptm), confirma com o dev e orienta distribuição ao cliente. Acione após /protheus:qa.
disable-model-invocation: true
---

Você vai conduzir a verificação final antes de liberar os artefatos para produção.

## HARD GATE

- **Leia `docs/plans/<plan>.gates.json`** e confirme: todas as chaves `ok` (reviews, lint, deploy, qa_e2e). Não confie em
  afirmação da conversa — o arquivo é a fonte de verdade (pipeline retomável).

Não inicie a verificação se:
- QA não foi concluído com sucesso
- Existem riscos ALTOS não resolvidos

## Passo 1 — Checklist de conformidade TOTVS

Verifique cada item obrigatório:

### 1.1 — MIT043 (Registro de Customizações)
- [ ] Todos os artefatos estão registrados no MIT043
- [ ] Descrição funcional preenchida
- [ ] Módulo e sequencial corretos

### 1.2 — Code Analysis
- [ ] Todos os fontes passaram no https://codeanalysis.totvs.com.br
- [ ] Sem violações críticas pendentes

### 1.3 — Patch .ptm
- [ ] Patch gerado com todos os artefatos
- [ ] Patch testado em ambiente de homologação
- [ ] Nome do patch segue convenção do cliente

### 1.4 — Documentação
- [ ] ProtheusDoc completo em todas as User Functions
- [ ] README ou instruções de aplicação do patch para o cliente

### 1.5 — Git
- [ ] Branch seguindo convenção: `homologacao/feature/[nome-da-demanda]`
- [ ] Commits com mensagens descritivas
- [ ] PR criado (se aplicável)

### 1.6 — Regressão do legado
- [ ] O cabeçalho do plano tem a linha `**Regressão:**` — apontando para o arquivo
      **ou** com justificativa explícita de "não se aplica". Cabeçalho sem a linha =
      Passo 3.5 do plan foi pulado → **bloqueia** (não é "não se aplica")
- [ ] O arquivo `docs/legado/regressao/<slug>.md` referenciado existe e **cada item
      tem veredito registrado**: verificado / não verificado / quebrou
- [ ] Itens com cenário E2E: verde no `.gates.json` (`qa_e2e.status = "ok"`), com o
      cenário nomeado pelo ID do item nas evidências
- [ ] Itens verificados por inspeção: `arquivo:linha` conferido no fonte final
- [ ] Item que deixou de valer foi para "Arquivadas" com motivo — não apagado
- [ ] Item sem veredito **bloqueia o verify**

## Passo 2 — Confirmar com o usuário

Use `AskUserQuestion`:

```
Checklist de verificação final:

[apresentar resultado de cada item]

Itens pendentes: [listar se houver]

Confirma liberação para produção?
```

## Passo 2.5 — Writeback: devolver a entrega ao mapa do legado

O `docs/legado/<fatia>.md` só cresce **antes** da demanda, pela `/protheus:arqueologia`.
Se nada for devolvido depois do ship, o mapa envelhece no instante em que o patch sai:
a próxima demanda na mesma fatia lê um retrato do legado que esta demanda já mudou — e
o `/protheus:brainstorm` ancora o design nele. Confirmada a liberação (Passo 2), faça
os três registros abaixo. **Nada aqui bloqueia — bloquear é papel do 1.6.** Este passo
é o que paga a próxima demanda.

### 2.5.1 — Itens novos em `docs/legado/regressao/<slug>.md` (append-only, mesma numeração `W`)

O Passo 3.5 do `/protheus:plan` escreveu o que **existia antes**. Agora, com o código
compilado e o E2E verde, escreva o que **passou a existir**:

1. **Comportamento que esta entrega estabeleceu** e que outra demanda pode desfazer sem
   perceber. Só entra o que tem forma de verificar (cenário E2E do `/protheus:qa` ou
   `arquivo:linha` no fonte final) e só CONFIRMADO — o resto vai para "Observações".
2. **Item da lista original que a entrega provou errado** vai para "Arquivadas" **com o
   motivo e a data** — nunca apagado, nunca corrigido no lugar. Item invalidado por
   feedback do dev/cliente durante a homologação conta aqui: o motivo é o que impede a
   próxima demanda de reintroduzir o problema.
3. **Item que aponta para fora deste repositório** (robô/RPA do cliente, integração
   Fluig, job agendado) entra com o repositório ou sistema no campo Origem. O ciclo
   não roda lá — o item é o que avisa.

### 2.5.2 — Registro de entrega em `docs/legado/<fatia>.md`

Acrescente uma linha à seção `## Entregas` (crie a seção se não existir; não reescreva
nada do que já está lá — vale o append-only do Passo 5 da `/protheus:arqueologia`):

| Data | Demanda | Fontes criados/alterados | PEs afetados | RN novas ou alteradas | Regressão |
|---|---|---|---|---|---|
| 2026-08-08 | TICKET-123 (`<slug>`) | `RFATA001.prw` (novo) | `MT410TOK` | `RN-FAT-07` (nova — `RFATA001.prw:88`) | `docs/legado/regressao/<slug>.md` |

- **Só o que está no fonte final entra** — a linha sai do artefato compilado no patch,
  não do design doc. Design é intenção; a fatia registra o que ficou no RPO.
- Regra de negócio que a demanda **criou ou mudou** entra numerada (`RN-<MOD>-NN`,
  continuando a sequência do arquivo) com `arquivo:linha` — rótulo CONFIRMADO por
  construção: você acabou de ler o fonte liberado.
- Fatia sem mapa: crie o arquivo só com o cabeçalho de extração parcial e a seção
  `## Entregas`. Registro de entrega **não é arqueologia** — não saia inventariando.

### 2.5.3 — `docs/legado/COBERTURA.md`

Acrescente o ticket desta entrega à coluna `Demanda` da fatia tocada.

> Entrega que não volta pro mapa é conhecimento que morre no patch.

## Passo 3 — Orientar distribuição

```
✅ VERIFICAÇÃO CONCLUÍDA — [nome da demanda]

Mapa do legado atualizado (Passo 2.5):
- docs/legado/[fatia].md — Entregas: +1 · RN novas: [lista ou "nenhuma"]
- docs/legado/regressao/[slug].md — itens novos: [N] · arquivados: [N]
(se o 2.5 foi pulado, diga "writeback NÃO feito" — omissão visível, não silêncio)

Artefatos aprovados:
- [listar artefatos com tipo]

Patch: [nome.ptm]
Ambiente testado: [servidor:porta/env]
Testes E2E (Playwright): [N] cenários passando

Próximos passos para produção:
- [ ] Registrar fontes no MIT043 (se ainda não feito)
- [ ] Validar em https://codeanalysis.totvs.com.br
- [ ] Criar/mergear PR em: homologacao/feature/[nome-da-demanda]
- [ ] Distribuir patch ao cliente para aplicação em produção
- [ ] Agendar aplicação com o cliente (janela de manutenção)
```

## Ciclo Encerrado

```
Ciclo de desenvolvimento concluído.

Todos os gates passaram:
  ✅ Implementação (teammates sonnet)
  ✅ Review spec + qualidade
  ✅ Lint gate (advpls appre)
  ✅ Deploy compilado (patch .ptm)
  ✅ QA E2E Playwright
  ✅ Verificação TOTVS (MIT043, Code Analysis)

Os artefatos estão aprovados para produção.
```

## Regras obrigatórias

- Todos os itens do checklist devem ser verificados — não pule
- MIT043 é obrigatório antes de distribuir ao cliente
- Code Analysis é obrigatório antes de mergear PR
- Sempre confirmar com o usuário antes de declarar aprovado
- Se itens pendentes: resolva antes de liberar

---

## Consulta de Conhecimento

Se precisar de informação não disponível no MCP, consulte o RAG:
```
searchKnowledge({ keyword: "<termo relevante>" })
```
