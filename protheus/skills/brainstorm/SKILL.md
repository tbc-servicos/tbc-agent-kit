---
name: brainstorm
description: Planejamento de desenvolvimento ADVPL/TLPP — intake de MIT044, explora o projeto, pergunta em rodadas com resposta recomendada e gera design aprovado antes de qualquer código. Use ao iniciar qualquer nova feature ou desenvolvimento Protheus. Encadeia /protheus:plan.
---

<HARD-GATE>
Não gere nenhum código ADVPL/TLPP, não crie arquivos .prw/.tlpp e não invoque nenhum skill de implementação antes de apresentar o design e obter aprovação do desenvolvedor.
</HARD-GATE>

<HARD-GATE-MODELO>
Brainstorm é design, e design roda em **opus**. Antes do Passo 0, verifique
qual modelo está atendendo esta sessão. Se **não** for opus, PARE e responda exatamente:

> ⚠️ O brainstorm exige o modelo **opus** (regra de modelos deste plugin).
> Sessão atual: `<modelo>`. Rode `/model opus` e chame `/protheus:brainstorm` de novo.

Não explore o projeto, não faça as perguntas do Passo 2 e não gere design fora do opus.
Só siga em outro modelo se o desenvolvedor mandar seguir mesmo assim, por escrito, nesta
conversa — e registre isso no design doc.
</HARD-GATE-MODELO>

## Passo 0 — Documento de desenvolvimento

Antes de qualquer exploração, pergunte:

> "Existe um documento de desenvolvimento (MIT044) ou levantamento de requisitos
> para esta tarefa? Se sim, informe o caminho do arquivo."

**Se o desenvolvedor informar o caminho:**
1. Leia o documento completo
2. Extraia automaticamente: módulo, tabelas envolvidas, tipo de artefato,
   regras de negócio e restrições
3. Apresente um resumo do que foi extraído e confirme com o desenvolvedor
4. Use esses dados como contexto primário nas perguntas do Passo 2 —
   só pergunte o que estiver faltando ou ambíguo no documento

**Se não houver documento:**
- Continue normalmente para o Passo 1

---

## Passo 1 — Explorar o projeto

Percorra o projeto antes de qualquer pergunta:

```bash
# Fontes existentes e padrão de nomenclatura
find . -name "*.prw" -o -name "*.tlpp" | sort

# CLAUDE.md — configuração do cliente
cat CLAUDE.md 2>/dev/null

# MIT043 — registro de customizações já feitas
find . -name "MIT043*" | head -3 | xargs cat 2>/dev/null

# Commits recentes — o que foi feito
git log --oneline -15 2>/dev/null

# Pontos de Entrada existentes (prefixo PE_ ou padrão legado)
grep -rn "User Function" . --include="*.prw" --include="*.tlpp" | grep -i "^.*PE_\|^.*MT\|^.*FA" | head -20
```

Leia também, se existirem:
- `docs/legado/<fatia>.md` e `docs/legado/COBERTURA.md` — mapa da `/protheus:arqueologia`.
  Fatia da demanda fora das fatias mapeadas na COBERTURA e base cheia de customização
  não documentada? Ofereça rodar `/protheus:arqueologia` antes de seguir.
- `docs/legado/regressao/*.md` das demandas anteriores na mesma fatia — cada item é
  **restrição** do design, não sugestão.

Com base na exploração, identifique:
- Próximo sequencial disponível no padrão `R[MOD][TYPE][SEQ]`
- Módulos já desenvolvidos neste projeto
- Padrão de namespace TLPP, se houver
- Pontos de Entrada já customizados (para evitar duplicidade)

> Exploração longa (repositório grande, varredura de PEs) roda em **subagente**, em
> paralelo. Não segure a primeira rodada de perguntas esperando o resultado: só as
> perguntas que dependem dele esperam.

---

## Passo 1.5 — Consultar base de conhecimento (MCP obrigatório)

Consulte o MCP `tbc-knowledge` em dois momentos — as consultas **genéricas** agora,
antes de qualquer pergunta; as **parametrizadas** assim que tiver módulo e tabelas
(do MIT044 do Passo 0, ou das respostas da rodada 1 do Passo 2). Não chute o
parâmetro de uma consulta parametrizada: se módulo/tabela ainda não foram
respondidos, a consulta espera a rodada 1.

```
# Genéricas — rodam já:
searchKnowledge({ skill: "protheus-patterns", keyword: "nomenclatura" })
searchKnowledge({ skill: "protheus-patterns", keyword: "tratamento erros" })
ragSearchDocs({ query: "<modulo ou funcionalidade>" })

# Parametrizadas — rodam quando módulo/tabelas estiverem definidos:
searchFunction({ module: "<MOD>", limit: 20 })
searchKnowledge({ keyword: "ponto de entrada <rotina>" })   # PEs (findEndpoint é REST, não PE)
findExecAuto({ target: "<rotina>" })                        # (se disponível no seu tier — senão use ragSearchKnowledge)
findMvcPattern({ table: "<alias>" })                        # (se disponível no seu tier — senão use ragSearchKnowledge)
findEndpoint({ keyword: "<recurso>" })                      # só se a demanda envolver API REST
```

Use os resultados para:
- Identificar se já existe função/PE que resolve o caso
- Evitar reescrever comportamento já fornecido pelo ERP
- Embasar as abordagens propostas no Passo 3 com evidências da Knowledge Base

### Regra — fato é meu, decisão é sua

**Achar fato é trabalho seu, nunca do dev.** Se a resposta está no repositório, no
MCP `tbc-knowledge`, no dicionário de dados ou no ambiente (existe PE para esta rotina?
qual o próximo sequencial? qual o tipo do campo no SX3?), vá buscar — não pergunte.
Busca cara, despache um subagente (`Agent`).

**Decisão é do dev.** Trade-off, regra de negócio, prioridade, o que o cliente
aceita — apresente com recomendação e espere a resposta.

Teste rápido: se duas pessoas com acesso ao mesmo ambiente chegariam à mesma
resposta, é fato — busque. Se depende do que o cliente quer, é decisão — pergunte.

Subagente rodando é pré-requisito não resolvido, não pausa da entrevista: só as
perguntas que dependem daquele fato esperam o retorno. O resto da fronteira você
pergunta agora, enquanto ele roda.

---

## Passo 2 — Perguntas (em rodadas, com resposta recomendada)

Monte a **árvore de decisão** da tarefa e trabalhe por **rodadas**. A **fronteira** é o
conjunto de decisões cujos pré-requisitos já estão resolvidos — as que dá para perguntar
**agora** sem chutar resposta que você ainda não ouviu.

Pergunte a fronteira **inteira em uma única mensagem** (use `AskUserQuestion` com
múltiplas questões; múltipla escolha sempre que possível). Depois **pare e espere** as
respostas — não avance para o design com pergunta em aberto. Cada resposta empurra a
fronteira: decisões resolvidas destravam as que dependiam delas. Recalcule e faça a
próxima rodada.

**Regra de dependência:** pergunta cuja resposta depende de outra pergunta ainda
aberta **nesta** rodada pertence à rodada **seguinte** — nunca à atual.

### Formato de cada pergunta

Toda pergunta sai com a sua recomendação junto — o dev decide, mas nunca no escuro:

> ❓ **P1 — <título da decisão>**: <pergunta, com as alternativas quando houver>
>
> ➡️ **Recomendo:** <sua resposta> — <motivo em uma linha>
> `[CONFIRMADO | INFERIDO]` · fonte: <retorno do MCP, fonte do projeto, convenção do CLAUDE.md>

O rótulo segue a escala do `/protheus:specialist` (seção 5.5): CONFIRMADO só com
código ou retorno da KB destilada de código; documentação sozinha é INFERIDO.

Sem evidência, não recomende: diga o que faltou e volte ao Passo 1.5 para buscar antes
de perguntar. Recomendação sem fonte é chute com aparência de análise.

### Raiz da árvore — rodada 1

1. **O que você precisa construir?** (descrição livre)
2. **Qual tipo de artefato?**
   - `A` Cadastro/atualização (User Function ou MVC)
   - `E` Processamento/ExecBlock (função, consulta, relatório)
   - `P` Ponto de Entrada (MVC ou legado)
   - `R` Relatório
3. **Qual módulo?** (FAT, FIN, EST, COM, RH…)
4. **Quais tabelas são envolvidas?** (ex: SA1 Clientes, SC5 Pedidos)

> Itens 3 e 4 só entram na rodada 1 se o MIT044 do Passo 0 não os respondeu.

**Entre a rodada 1 e a rodada 2**, rode as consultas parametrizadas do Passo 1.5
com o módulo e as tabelas respondidos.

### Rodada 2 — depende das respostas e do MCP

5. **Qual Ponto de Entrada usar?** — *não pergunte se existe PE: o
   `searchKnowledge({ keyword: "ponto de entrada <rotina>" })` acabou de responder.*
   Apresente os PEs encontrados, com o que cada um permite, sua recomendação e o
   motivo — e peça a escolha.
6. **Precisa persistir dados?** Se sim, em tabela padrão ou customizada?
7. **Há validações ou regras de negócio específicas do cliente?**

### Ramos que as respostas abrem (rodadas 3+)

A raiz não é a árvore inteira. Cada resposta abre decisões que só existiam depois
dela — não deixe passar em silêncio:

| Resposta da raiz | Decisões que ela abre |
|---|---|
| Tabela customizada | prefixo e faixa no dicionário, campos `X_`, índices SIX, exclusiva ou compartilhada, registro no MIT043 |
| Ponto de Entrada | qual PE exatamente, o que retornar, comportamento em erro (aborta a gravação ou só avisa?), efeito em ExecAuto e dentro de loop |
| MVC completo | Modelo 1 ou 3, grid, validação de linha vs de modelo, momento do commit |
| Relatório | volume esperado, filtros, saída (tela / planilha / SmartView) |
| Persistência em tabela padrão | campos customizados necessários, impacto em rotinas TOTVS que já gravam nela |

**Quando parar:** a entrevista termina quando a **fronteira está vazia** — todo ramo da
árvore visitado e nada assumido em silêncio. "Já tenho informação suficiente" não é
condição de parada — é a sensação que costuma vir logo antes do retrabalho. Antes de
passar ao Passo 3, liste cada premissa que você está adotando sem ter perguntado; se
essa lista não estiver vazia, a fronteira também não está: volte e pergunte.

---

## Passo 3 — Propor 2-3 abordagens

Apresente as opções com trade-offs e sua recomendação. Exemplos de eixos de decisão:

| Decisão | Opção A | Opção B |
|---------|---------|---------|
| Estrutura | User Function simples | MVC completo |
| PE | Ponto de Entrada MVC | Ponto de Entrada legado |
| Persistência | Tabela padrão (SA1…) | Tabela customizada (SZ?) |
| Linguagem | ADVPL `.prw` | TLPP `.tlpp` com namespace |

Sempre indique qual você recomenda e por quê.

---

## Passo 4 — Apresentar design

Apresente o design em seções, aprovando em três blocos: (4.1–4.2), (4.3–4.4) e
(4.5–4.6). Aguarde a aprovação de cada bloco antes do seguinte.

### 4.1 — Visão geral
- Nome do arquivo: `R[MOD][TYPE][SEQ].prw` (ou `.tlpp`)
- Tipo de artefato e responsabilidade
- Módulo e próximo sequencial

### 4.2 — Estrutura de funções
- `User Function` principal (nome ≤ 8 chars para `.prw`)
- `Static Function` auxiliares
- Ponto de Entrada (se aplicável) — PE em arquivo próprio, lógica em função externa

### 4.3 — Acesso a dados
- Tabelas lidas e gravadas
- `RecLock / MsUnlock / dbCommit` onde necessário
- `xFilial()` obrigatório em toda busca

### 4.4 — Tratamento de erros
- Programação defensiva com guard clauses, conforme as convenções inegociáveis do
  CLAUDE.md do plugin (Try-Catch em TLPP, ErrorBlock só em ADVPL clássico,
  **BEGIN SEQUENCE PROIBIDO**)
- Mensagens ao usuário

### 4.5 — Checklist de conformidade
- Convenções inegociáveis do CLAUDE.md do plugin (notação húngara, escopos, tratamento de erros)?
- Limite de 8 chars no nome da User Function (`.prw`)?
- ProtheusDoc completo?
- Registrar no MIT043?

### 4.6 — Premissas e aceites registrados

Registre aqui os aceites por escrito que o dev deu durante o Passo 2 (premissa
aceita + justificativa). Se ao montar o design surgir premissa **nova** que não
passou pelo Passo 2, ela não entra nesta lista: vira pergunta agora — e a resposta
**invalida os blocos já aprovados que ela sustenta**, que devem ser reapresentados.

Design aprovado com premissa em aberto não é design aprovado — é retrabalho
agendado, e o implementador vai decidir sozinho o que você não perguntou.

---

## Passo 5 — Transição para planejamento

Após aprovação do design, salve o design doc em `docs/plans/YYYY-MM-DD-[modulo]-[descricao]-design.md`.

Grave também o vínculo em `docs/plans/YYYY-MM-DD-[modulo]-[descricao].gates.json` — o
mesmo arquivo que o `/protheus:implement` usa como estado dos gates, criado uma etapa
antes:

```json
{
  "slug": "YYYY-MM-DD-[modulo]-[descricao]",
  "design": { "status": "aprovado", "doc": "docs/plans/YYYY-MM-DD-[modulo]-[descricao]-design.md" },
  "plan":   { "status": "pendente" }
}
```

Se já existir `.gates.json` **com este mesmo slug** (re-brainstorm da mesma feature),
não regrave o template: atualize **só** a chave `design` e preserve todas as demais
(`plan`, `spec_review`, `code_review`…) — sobrescrever apagaria os gates de execução já
conquistados. Se o design mudou depois de implementação feita, avise o dev que os
gates gravados podem não valer mais e pergunte se zera.

Se existir `.gates.json` de **outra** feature em andamento, apenas avise o dev que há
mais de uma feature aberta.

Anuncie:

```
Design aprovado!

Próximo passo:
  /protheus:plan
```

> O `protheus:plan` irá decompor o design em tasks tipadas para ADVPL
> e preparar o plano para os teammates de implementação, revisão, compilação e testes E2E Playwright.
