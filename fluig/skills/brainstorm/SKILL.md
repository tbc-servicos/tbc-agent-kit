---
name: brainstorm
description: Gate de design para desenvolvimento Fluig. O dev roda /fluig:brainstorm ANTES de criar qualquer artefato (widget, form, dataset, workflow). Levanta os fatos do projeto, entrevista o desenvolvedor em rodadas com resposta recomendada, mapeia integrações e produz um design aprovado antes de acionar qualquer skill de scaffolding.
disable-model-invocation: true
---

Você está iniciando o planejamento de uma funcionalidade Fluig. Nenhum código será gerado até o design ser aprovado.

## HARD GATE

Não gere nenhum código, não crie arquivos de artefato Fluig e não invoque nenhuma skill
de scaffolding ou implementação antes de ter o design aprovado pelo usuário nesta skill.

## HARD GATE — modelo opus

Brainstorm é design, e design roda em **opus**. Antes do Passo 0, verifique qual
modelo está atendendo esta sessão. Se **não** for opus, PARE e responda exatamente:

> ⚠️ O brainstorm exige o modelo **opus** (regra de modelos deste plugin).
> Sessão atual: `<modelo>`. Rode `/model opus` e chame `/fluig:brainstorm` de novo.

Não faça as perguntas do Passo 1 e não gere design fora do opus. Só siga em outro modelo se
o desenvolvedor mandar seguir mesmo assim, por escrito, nesta conversa — e registre isso no
design aprovado.

## Passo 0 — Levantar os fatos (antes de perguntar qualquer coisa)

Antes da primeira pergunta, levante você mesmo:

```bash
cat CLAUDE.md 2>/dev/null                 # prefixos e convenções do projeto
find . -name "*.js" -path "*dataset*"     # datasets existentes
find . -type d -name "wg_*"               # widgets existentes
git log --oneline -15 2>/dev/null         # o que foi feito recentemente
```

Consulte também o MCP para o tipo de artefato em questão:

```
searchKnowledge({ platform: "fluig", skill: "<tipo do artefato>", keyword: "template" })
ragSearchKnowledge({ query: "<o que a demanda precisa fazer no Fluig>" })
```

Leia também, se existirem:
- `docs/legado/<fatia>.md` e `docs/legado/COBERTURA.md` — mapa da `/fluig:arqueologia`
  (o ambiente do cliente, com escala de confiança). Fatia da demanda fora das fatias
  mapeadas e ambiente cheio de artefato não documentado? Ofereça rodar
  `/fluig:arqueologia` antes de seguir.
- `docs/legado/regressao/*.md` das demandas anteriores na mesma fatia — cada item é
  **restrição** do design, não sugestão.

**Fato é trabalho seu, decisão é do dev.** Se está no repositório, no MCP ou no
ambiente, busque — não pergunte. Trade-off e regra de negócio, pergunte. Busca cara
roda em subagente e não bloqueia a rodada: só as perguntas que dependem dela esperam
o retorno — o resto da fronteira você pergunta agora.

## Passo 1 — Entender o artefato (rodada 1)

Use `AskUserQuestion` com as perguntas abaixo em uma única chamada com múltiplas
questões. Em toda pergunta de múltipla escolha, marque qual opção você recomenda e
por quê — com a evidência do Passo 0 ou do MCP. O dev decide, mas nunca no escuro.

**Teto de confiança:** a KB fluig vem de **documentação processada, não de
código-fonte** — recomendação sustentada só pelo MCP é rotulada `INFERIDO`, nunca
`CONFIRMADO`. `CONFIRMADO` exige fato lido do próprio projeto (Passo 0) ou do
ambiente. O que depender do ambiente do cliente e você não puder ver é `LACUNA` —
vira pergunta, não suposição.

O rótulo aparece **na própria recomendação**, sempre neste formato:

> ➡️ **Recomendo:** <opção> — <motivo em uma linha>
> `[CONFIRMADO | INFERIDO]` · fonte: <artefato do Passo 0, retorno do MCP, CLAUDE.md do projeto>

E no design do Passo 2, toda `LACUNA` vai obrigatoriamente para a seção
"Riscos e premissas".

**Pergunta 1:** Qual(is) artefato(s) será(ão) criado(s)?
- Widget Angular (tela interativa)
- Formulário Fluig (form nativo)
- Dataset (fonte de dados)
- Workflow / evento BPM
- Combinação de múltiplos artefatos

**Pergunta 2 (aberta):** Qual é a necessidade de negócio? O que o usuário final vai conseguir fazer?

**Pergunta 3:** Há integração com outros sistemas?
- Protheus REST API
- Outro dataset Fluig existente
- Workflow existente
- Nenhuma integração externa

**Pergunta 4** *(pule se o Passo 0 não encontrou artefato nenhum — projeto novo)*:
Encontrei estes artefatos no projeto: `<lista do Passo 0>`. Algum deles deve ser
reaproveitado ou modificado? *(não pergunte se existem artefatos — isso você já
levantou no Passo 0)*
- Sim — quais
- Não, tudo novo

## Passo 1.5 — Rodadas seguintes (a fronteira)

As perguntas do Passo 1 são a **raiz** da árvore de decisão, não a entrevista inteira.
Cada resposta abre decisões que dependiam dela — pergunte-as em uma nova rodada,
agrupadas, antes de montar o design:

| Resposta da raiz | Decisões que ela abre |
|---|---|
| Widget Angular | de onde vêm os dados, paginação ou carga total, comportamento em erro de rede, permissão por papel |
| Dataset | dataset de serviço ou customizado, constraints obrigatórias, volume e timeout, cache |
| Workflow / evento BPM | qual evento exatamente, o que fazer se o evento falhar (trava a atividade?), reprocessamento |
| Integração Protheus REST | autenticação, timeout e retry, o que o usuário vê quando o Protheus está fora |

**Regra de dependência:** pergunta cuja resposta depende de outra pergunta ainda
aberta **nesta** rodada pertence à rodada **seguinte** — nunca à atual.

**Quando parar:** a entrevista termina quando a fronteira está vazia **e** não sobrou
premissa sua sem resposta — liste cada decisão que você adotou sem perguntar; se a
lista não está vazia, a fronteira também não está (o que o dev aceitar por escrito
fica registrado na seção "Riscos e premissas" do design). Só então vá para o Passo 2.

## Passo 2 — Apresentar o design

Com base nas respostas, apresente um design estruturado contendo:

### Artefatos a criar
Liste cada artefato com nome (seguindo convenção do projeto: prefixo do CLAUDE.md), tipo e responsabilidade.

### Integrações mapeadas
Para cada integração: endpoint ou artefato de origem, dados consumidos, tratamento de erro esperado.

### Fluxo do usuário
Descreva em 3-5 passos o que o usuário final vai fazer e o que cada artefato entrega.

### Dependências entre artefatos
Se houver múltiplos artefatos: qual precisa existir antes do outro? Ex: dataset antes do widget.

### Riscos e premissas (esta lista tem que sair vazia)
Liste tudo que ainda não está claro e toda decisão que **você** tomou sem perguntar.
Cada item é uma pergunta da próxima rodada, não um aviso no rodapé do design. Só
permanece na lista o que o dev declarar, por escrito, que aceita assumir — com o
motivo registrado ao lado. Não avance para o Passo 3 com item pendente sem esse aceite.

## Passo 3 — Aprovação

Apresente o design e pergunte:

> "Este design está correto? Posso prosseguir com o scaffolding?"

**Se aprovado:**

1. Salve o design como spec em `docs/fluig/specs/YYYY-MM-DD-<topic>.md`
2. Anuncie:

```
Design aprovado e salvo em docs/fluig/specs/[arquivo].

Próximo passo: /fluig:plan → criar plano de implementação com tasks detalhadas
```

**Se não aprovado:** revise o design com base no feedback e apresente novamente.
