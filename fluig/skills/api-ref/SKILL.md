---
name: api-ref
description: Referência das APIs TOTVS Fluig — DatasetFactory, DatasetBuilder, CardAPI, WCMAPI, fluigc, WFMovementDTO, getValue/setValue. Use quando tiver dúvida sobre qual API usar no Fluig, sintaxe de dataset, como manipular formulário, ou diferença entre APIs de workflow e formulário.
---

## Boas práticas

- Use a referência para identificar APIs, parâmetros e padrões — não cole trechos longos de código de terceiros
- Para customizações, crie datasets, widgets e workflows próprios em vez de duplicar comportamento já fornecido pelo Fluig
- Quando precisar de detalhe de implementação interno do Fluig, oriente o usuário a consultar o **TDN oficial** (tdn.totvs.com)

# Fluig API Reference

Referência das APIs TOTVS Fluig via MCP `tbc-knowledge`.

## As três tools, e o que cada uma responde

| Tool | O que tem dentro | Use para |
|---|---|---|
| `searchKnowledge({ platform: "fluig", keyword })` | conhecimento curado por skill/categoria | convenção, padrão, template, regra de review |
| `ragSearchKnowledge({ query })` | busca semântica sobre a base de conhecimento | pergunta em linguagem natural, quando você não sabe o termo exato |
| `ragSearchDocs({ query })` | busca semântica sobre a documentação processada | assinatura de API, parâmetro, comportamento documentado |

**Comece pela `searchKnowledge` com o termo técnico exato.** Se não souber o termo, ou
se a busca por palavra-chave vier vazia, caia para `ragSearchKnowledge`/`ragSearchDocs`,
que aceitam a pergunta inteira.

> A busca por palavra-chave é sensível a acento: `validação` e `validacao` não são o
> mesmo termo. Na dúvida, tente os dois — ou use a busca semântica.

## O que buscar, para quê

### APIs por área

```
searchKnowledge({ platform: "fluig", keyword: "DatasetFactory" })    // datasets, constraints
searchKnowledge({ platform: "fluig", keyword: "CardAPI" })           // formulário: getValue/setValue
searchKnowledge({ platform: "fluig", keyword: "WCMAPI" })            // contexto/sessão do WCM
searchKnowledge({ platform: "fluig", keyword: "WFMovementDTO" })     // workflow: movimentação
searchKnowledge({ platform: "fluig", keyword: "fluigc" })            // componentes fluigc (modal, message)
```

Assinatura ou comportamento que a busca por palavra-chave não devolve:

```
ragSearchDocs({ query: "parâmetros do createDataset no Fluig" })
ragSearchDocs({ query: "quais variáveis WK estão disponíveis no evento de workflow" })
```

### Padrões, convenções e templates

```
searchKnowledge({ platform: "fluig", skill: "dataset", keyword: "template" })
searchKnowledge({ platform: "fluig", skill: "form", keyword: "validação" })
searchKnowledge({ platform: "fluig", skill: "workflow", keyword: "evento" })
searchKnowledge({ platform: "fluig", skill: "widget", keyword: "template" })
searchKnowledge({ platform: "fluig", keyword: "nomenclatura" })
searchKnowledge({ platform: "fluig", skill: "review", keyword: "review" })
```

Vocabulário de `skill` que existe na base: `fluig` · `client-fluig` · `widget` ·
`form` · `workflow` · `dataset` · `review` · `debug` · `api-ref`. **Não invente
filtro** — nome de categoria que não existe nos dados devolve vazio, e vazio é lido
como "não existe padrão para isso", que é a conclusão errada.

## Quando usar cada tool

| Dúvida | Consulta |
|--------|----------|
| Qual método usar para consultar dataset? | `searchKnowledge({ platform: "fluig", keyword: "DatasetFactory" })` |
| Como obter valor de campo no formulário? | `searchKnowledge({ platform: "fluig", keyword: "getValue" })` |
| Quais variáveis WK* existem no workflow? | `ragSearchDocs({ query: "variáveis WK disponíveis no workflow Fluig" })` |
| Como estruturar um dataset corretamente? | `searchKnowledge({ platform: "fluig", skill: "dataset", keyword: "template" })` |
| Qual a convenção de nomenclatura? | `searchKnowledge({ platform: "fluig", keyword: "nomenclatura" })` |
| O código passa no review? | `searchKnowledge({ platform: "fluig", skill: "review", keyword: "review" })` |
| Não sei nem o nome da API que preciso | `ragSearchKnowledge({ query: "<a pergunta inteira>" })` |
