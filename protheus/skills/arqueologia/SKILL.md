---
name: arqueologia
description: Mapeia a fatia do legado do cliente que a demanda atual vai tocar — customizações existentes, Pontos de Entrada, tabelas e campos customizados, regras de negócio embutidas — e grava em docs/legado/ com escala de confiança. Extração parcial e append-only, o mapa cresce por demanda. Use antes do /protheus:brainstorm quando a área da demanda não tiver mapa.
---

<HARD-GATE>
Escopo é a fatia que a demanda toca, nunca a base inteira. Se o mapa que você está
prestes a escrever não cabe em uma sessão, o escopo está errado — volte e reduza.
Esta skill NÃO gera código e NÃO modifica fonte nenhum: escreve apenas em `docs/legado/`.
</HARD-GATE>

Toda afirmação do mapa sai rotulada com a escala do `/protheus:specialist` (seção 5.5):
**CONFIRMADO** (lido no fonte, no SX3 do ambiente ou no retorno do MCP sobre código) ·
**INFERIDO** (padrão TOTVS, convenção, dicionário padrão não conferido no cliente) ·
**LACUNA** (não sei e não consegui descobrir — precisa do dev, do cliente ou do ambiente).

## Passo 0 — Escopo e profundidade

Pergunte ao dev, com `AskUserQuestion`:

1. **Qual a fatia?** (módulo, rotina, tabela ou processo que a demanda toca)
2. **Qual profundidade?**
   - `1` **Essencial** (padrão) — inventário + regras de negócio das customizações da fatia
   - `2` **Completo** — inclui dicionário customizado (campos `X_`, índices SIX,
     parâmetros `MV_`/`TB_`) e mapa de Pontos de Entrada por rotina
   - `3` **Detalhado** — inclui arqueologia de Git por fonte e fluxo por função não-trivial

Profundidade 3 numa fatia grande estoura a sessão. Se o dev pedir 3, confirme o
tamanho da fatia antes de começar.

## Passo 0.5 — Fatia já mapeada: conferir antes de acrescentar

Antes do inventário, olhe a `docs/legado/COBERTURA.md`. Se a fatia **já tem** linha lá,
esta rodada não é extração nova — é **conferência**. Mapa que ninguém confere envelhece
em silêncio, e o `/protheus:brainstorm` trata cada regra CONFIRMADO como restrição do
design: regra CONFIRMADO desatualizada é pior que LACUNA, porque ninguém desconfia dela.

Para cada `RN-<MOD>-NN` marcada **CONFIRMADO** no `docs/legado/<fatia>.md`, volte ao
`arquivo:linha` de origem e responda uma das três:

| Situação no fonte de hoje | O que fazer |
|---|---|
| A regra continua lá, igual | nada — não regrave a linha |
| O `arquivo:linha` mudou, o comportamento não | registre em `## Divergências desta rodada` citando a referência antiga e a nova |
| O comportamento mudou, ou o trecho sumiu | **achado**: `## Divergências desta rodada` com antes, depois e data; a regra antiga vai para "Arquivadas" **com o motivo** |

Comece pela seção `## Entregas` (o que o `/protheus:verify` devolveu ao mapa no Passo
2.5): entrega registrada ali que não aparece nas regras é onde a divergência está mais
provável.

Reporte a contagem de divergências no Passo 6, junto com as LACUNAs — é o número que
diz se o mapa desta fatia ainda vale alguma coisa.

## Passo 1 — Inventário da fatia (CONFIRMADO por construção)

```bash
find . -name "*.prw" -o -name "*.tlpp" | sort                # fontes
grep -rn "User Function" --include="*.prw" --include="*.tlpp" .   # entradas
grep -rln "<ALIAS>" --include="*.prw" --include="*.tlpp" .   # quem toca a tabela da demanda
git log --oneline --follow -- <fonte>                        # idade e churn de cada fonte
```

Para cada fonte da fatia registre: nome, módulo, tipo (User Function / PE / MVC /
relatório), data do último commit, e se está no MIT043.

**Divergência MIT043 × disco é achado próprio, não ruído — e não é LACUNA.** Fonte no
disco e ausente do MIT043 é customização que ninguém registrou: o comportamento dela é
CONFIRMADO (basta ler o arquivo); o que falta é **registro**. Liste essas divergências
em seção separada do mapa — é onde mora o comportamento que vai quebrar.

Inventário longo (base grande, varredura de PEs) roda em **subagente**, em paralelo —
não segure os outros passos esperando.

## Passo 2 — Pontos de Entrada por rotina

Para cada rotina TOTVS tocada pela demanda, liste os PEs já customizados no cliente,
o que cada um retorna e o que acontece se retornar `.F.`. Cruze com o MCP —
`searchKnowledge({ keyword: "ponto de entrada <PE ou rotina>" })` e
`searchFunction({ name: "<PE>" })` — para saber o que o PE **deveria** fazer
(INFERIDO) versus o que o fonte do cliente **faz** (CONFIRMADO). *(`findEndpoint`
não serve aqui: indexa endpoints REST, não Pontos de Entrada.)*

Dois PEs no mesmo ponto, ou lógica de negócio dentro do próprio arquivo de PE em vez
de função externa, são achados.

## Passo 3 — Dicionário customizado (profundidade 2+)

Campos `X_`/prefixo do cliente nas tabelas da fatia, com **tipo e tamanho reais do
SX3** — não deduzidos do nome. Índices SIX customizados. Parâmetros `MV_`/`TB_` que a
fatia lê. Sem ambiente à mão, use o dicionário padrão
(`https://terminaldeinformacao.com/wp-content/tabelas/<tabela>.php`, minúsculo) e
marque INFERIDO: o cliente pode ter alterado.

## Passo 4 — Regras de negócio embutidas

Do fonte, não da documentação: condicionais com lógica de domínio, validações,
constantes com nome de negócio, mensagens ao usuário, `TODO`/`FIXME`. Numere
`RN-<MOD>-01`, `RN-<MOD>-02`… Cada uma com rótulo de confiança e o `arquivo:linha`
de onde saiu.

Comentário antigo é **evidência de intenção, não prova de comportamento**: o que o
código faz é CONFIRMADO; o que o comentário diz que ele faz é INFERIDO.

## Passo 5 — Gravar (append-only)

`docs/legado/<fatia>.md`, com o cabeçalho:

> ⚠️ **Extração parcial.** Cobre apenas `<fatia>`, gerada em `<data>` para a demanda
> `<ticket>`. Append-only: rodadas futuras acrescentam, nunca reescrevem. Fora desta
> fatia, o mapa não existe.

E com estas seções fixas (crie vazias na primeira rodada — os outros passos e skills
escrevem nelas, e seção improvisada quebra o append-only na rodada seguinte):

- `## Regras` — as `RN-<MOD>-NN` do Passo 4
- `## Entregas` — preenchida pelo Passo 2.5 do `/protheus:verify`
- `## Divergências desta rodada` — preenchida pelo Passo 0.5 (conferência)
- `## Arquivadas` — regra que deixou de valer, sempre **com motivo e data**

E `docs/legado/COBERTURA.md`, **uma linha por fatia mapeada** (nunca uma por fonte —
catalogar a base inteira é exatamente o que o HARD-GATE proíbe):

| Fatia | Fontes cobertos | Demanda | Data |
|---|---|---|---|
| `faturamento-pedido` | `RFATA001.prw`, `PE_MT410TOK.prw` (+6) | TICKET-123 | 2026-08-08 |

E, no rodapé, a contagem do que **ninguém mapeou ainda** — o dado mais importante do
arquivo (obtida por `find`, atualizada a cada rodada):

> Fontes fora de qualquer fatia: **1.192** de 1.200. A contagem só diminui quando
> vira cobertura — nunca a reduza sem mapear.

## Passo 6 — Encerrar

Reporte: fontes inventariados, regras numeradas, quantas LACUNAs, divergências
MIT043, e a cobertura acumulada. Encaminhe para `/protheus:brainstorm`, que vai
ancorar o design neste mapa. **Não** gere código.
