---
name: arqueologia
description: Mapeia a fatia do ambiente Fluig do cliente que a demanda atual vai tocar — datasets, formulários, workflows e widgets PUBLICADOS, com as regras de negócio que carregam — e grava em docs/legado/ com escala de confiança. Sem código-fonte no repositório, o mapa sai do AMBIENTE (REST do Fluig e exportações do Studio); LACUNA frequente é normal aqui, não falha. Extração parcial e append-only. Use antes do /fluig:brainstorm quando a área da demanda não tiver mapa.
---

<HARD-GATE>
Escopo é a fatia que a demanda toca, nunca o ambiente inteiro. Se o mapa que você está
prestes a escrever não cabe em uma sessão, o escopo está errado — volte e reduza.
Esta skill NÃO gera código e NÃO modifica artefato nenhum: escreve apenas em `docs/legado/`.
</HARD-GATE>

**A diferença para o Protheus, dita de saída:** aqui normalmente **não há código-fonte
no repositório** — o que existe é o que está **publicado no servidor Fluig** do cliente.
O mapa sai do ambiente, e isso muda o teto de confiança:

- **CONFIRMADO** — você leu o artefato exportado/consultado do ambiente (o JS do
  dataset via export ou consulta, o XML/HTML do formulário, o fluxo do processo).
- **INFERIDO** — comportamento deduzido do que a base de conhecimento, a documentação
  ou o nome do artefato sugerem. A KB fluig vem de documentação, não de código:
  **retorno de MCP sozinho nunca passa de INFERIDO**.
- **LACUNA** — regra dentro de artefato que você **não conseguiu exportar nem
  consultar** (dataset builtin sem fonte visível, evento de processo inacessível).
  **LACUNA aqui é frequente e normal** — o valor do mapa é justamente dizer onde
  ninguém consegue ver.

## Passo 0 — Escopo e profundidade

Pergunte ao dev, com `AskUserQuestion`:

1. **Qual a fatia?** (processo, formulário, conjunto de datasets ou página/widget que
   a demanda toca)
2. **Qual profundidade?**
   - `1` **Essencial** (padrão) — inventário do publicado + regras de negócio visíveis
   - `2` **Completo** — inclui campos de formulário (nome, tipo, obrigatoriedade),
     constraints dos datasets e mapa de quem consome quem
   - `3` **Detalhado** — inclui eventos de processo/formulário exportados linha a
     linha e histórico de versões dos artefatos no servidor

## Passo 0.5 — Fatia já mapeada: conferir antes de acrescentar

Se a fatia já tem linha na `docs/legado/COBERTURA.md`, esta rodada é **conferência**,
não extração: revisite cada regra CONFIRMADO na origem (re-exporte/reconsulte o
artefato) e registre em `## Divergências desta rodada` o que mudou — a regra antiga
vai para "Arquivadas" com o motivo. Comece pela seção `## Entregas` (o que o
`/fluig:verify` devolveu ao mapa). Regra CONFIRMADO desatualizada é pior que LACUNA.

## Passo 1 — Inventário do publicado

**A via de consulta ao servidor é pré-requisito deste passo** — e o plugin não a
distribui. Em ordem de preferência:

1. **REST autenticada do Fluig** — `GET /ecm/api/rest/...`,
   `/process-management/api/v2/processes`, com credencial do ambiente do cliente
2. **Exportações do Studio/admin** fornecidas pelo dev ou pelo admin do cliente
3. **Nenhuma das duas** → o inventário vem do que o dev/admin declarar, e cada item
   entra como INFERIDO com a fonte "declarado por <quem>" — diga isso com todas as
   letras no cabeçalho do mapa

> `searchKnowledge`/`ragSearchKnowledge` são a base de padrões do plugin — dizem o que
> o Fluig **faz**, nunca o que **este cliente** tem publicado. Não servem de inventário.

Levante para a fatia:

- Datasets: nome, tipo (builtin / customizado), quem o consome
- Formulários: id, versão publicada, processo(s) que o usam
- Workflows: processo, versão, atividades e eventos anexados
- Páginas/widgets: página do portal, instâncias e parâmetros

Se o repositório TIVER fonte versionado (projeto novo), inventarie também o repo — aí
o teto volta a ser CONFIRMADO pelo código, como no Protheus.

**Divergência repositório × servidor é achado próprio**: artefato publicado sem fonte
no repo (ou fonte no repo diferente do publicado) é onde mora o comportamento que vai
quebrar. Liste em seção separada.

## Passo 2 — Regras de negócio visíveis

Do artefato exportado/consultado, não da documentação: validações de formulário,
condições de fluxo, constraints de dataset, mensagens ao usuário. Numere
`RN-<FATIA>-01`, `RN-<FATIA>-02`… com rótulo de confiança e a **origem** (artefato +
onde: evento, campo, atividade).

Regra dentro de artefato não exportável: registre como LACUNA **com o nome do
artefato** — é pergunta para o admin do ambiente, não suposição.

## Passo 3 — Gravar (append-only)

`docs/legado/<fatia>.md` com o cabeçalho:

> ⚠️ **Extração parcial, baseada no AMBIENTE `<servidor>` em `<data>`** para a demanda
> `<ticket>`. Append-only: rodadas futuras acrescentam, nunca reescrevem. Fora desta
> fatia, o mapa não existe. Artefato republicado depois desta data pode divergir.

E com estas seções fixas (crie vazias na primeira rodada — os outros passos e o
`/fluig:verify` escrevem nelas; seção improvisada quebra o append-only):

- `## Regras` — as `RN-<FATIA>-NN` do Passo 2
- `## Entregas` — preenchida pelo Passo 5.5 do `/fluig:verify`
- `## Divergências desta rodada` — preenchida pelo Passo 0.5 (conferência)
- `## Arquivadas` — regra que deixou de valer, sempre **com motivo e data**

E `docs/legado/COBERTURA.md`, **uma linha por fatia mapeada**, neste formato:

| Fatia | Artefatos cobertos | Demanda | Data |
|---|---|---|---|
| `pedido-compra` | `ds_pedidos`, form 12345, processo `PC_Aprovacao` | TICKET-123 | 2026-08-08 |

Com a contagem do não-mapeado no rodapé (datasets/forms/processos da instância fora
de qualquer fatia). A coluna `Demanda` acumula tickets — é onde o `/fluig:verify`
registra cada entrega.

## Passo 4 — Encerrar

Reporte: artefatos inventariados, regras numeradas, quantas LACUNAs (aqui o número
alto é informação, não vergonha), divergências repo × servidor, cobertura acumulada.
Encaminhe para `/fluig:brainstorm`, que vai ancorar o design neste mapa. **Não** gere
código.
