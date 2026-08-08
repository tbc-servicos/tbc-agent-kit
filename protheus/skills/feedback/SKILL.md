---
name: feedback
description: Registra um aprendizado de correção na base de conhecimento Protheus. Usar quando Claude erra e o dev corrige, para que o erro não se repita com outros devs. Conduz diálogo de confirmação antes de persistir.
---

# Protheus Feedback — Registro de Aprendizado

Use esta skill quando:
- Claude cometeu um erro que foi corrigido pelo dev
- Dev invocou explicitamente `/protheus:feedback`

**Regra inegociável:** nunca submeter sem confirmação explícita do dev.

---

## Passo 1 — Confirmar intenção

Perguntar ao dev:

> "Posso registrar esse aprendizado na base de conhecimento para que outros devs não recebam a mesma resposta errada?"

Aguardar confirmação. Se o dev recusar, encerrar sem insistir.

---

## Passo 2 — Gerar rascunho estruturado

Analisar o contexto da conversa (o que Claude disse de errado, o que o dev corrigiu) e propor:

```
❌ ERRO: <o que Claude gerou de incorreto — específico>
📍 CONTEXTO: <situação — rotina, módulo, padrão Protheus envolvido>
✅ REGRA: <o que está correto, de forma prescritiva e direta>
💻 EXEMPLO ERRADO:
   <código ADVPL/TLPP incorreto, se aplicável>
💻 EXEMPLO CORRETO:
   <código ADVPL/TLPP correto, se aplicável>
🏷 TAGS: <palavras-chave separadas por vírgula que Claude usaria ao buscar>
        ex: ExecAuto, MATA010, ErrorBlock, notação húngara, RecLock
```

---

## Passo 2.5 — Checar duplicata e contradição (antes de mostrar o rascunho)

A KB não tem supersessão automática — dois feedbacks contraditórios convivem, e quem
busca pode seguir o errado. Antes do Passo 3, busque o tema:

```
searchKnowledge({ keyword: "<termo central do erro>", limit: 5 })
```

Se vier registro próximo, mostre ao dev junto com o rascunho e pergunte:

> "Encontrei este(s) aprendizado(s) relacionado(s). O seu **complementa**, **corrige**
> ou **duplica** algum deles?"

- **Corrige** → abra o rascunho com a linha `⚠️ CORRIGE aprendizado de <data/autor>:`
  no campo ERRO, para quem buscar depois achar a versão nova junto da velha.
- **Duplica** → não submeta; avise o dev que já existe.

---

## Passo 3 — Dev revisa e aprova

Apresentar o rascunho e perguntar:

> "Esse rascunho está correto? Pode editar qualquer campo antes de confirmar."

Aguardar resposta. Aplicar edições se o dev solicitar. Só avançar após aprovação explícita.

---

## Passo 3.5 — Candidato a promoção? (ANTES de submeter — a tag entra no payload)

Junto da aprovação do rascunho, pergunte:

> "Esse erro é provável de se repetir com outros devs? Se sim, qual skill deveria
> **impedir** isso (reviewer, writer, patterns, hook de lint...)?"

Se o dev apontar destino, acrescente `promote:<skill>` (ex.: `promote:reviewer`) às
TAGS do rascunho **antes** do Passo 4 — o `submitFeedback` não tem update: tag que
não entra na submissão não existe. É o filtro que a revisão periódica usa para
decidir o que sai da KB e vira regra de skill.

---

## Passo 4 — Submeter via MCP

Chamar a tool MCP `submitFeedback` com os campos aprovados:

```
submitFeedback({
  plugin:      "protheus",
  error:       <campo ERRO>,
  context:     <campo CONTEXTO ou null se não informado>,
  rule:        <campo REGRA>,
  example_bad: <EXEMPLO ERRADO ou null>,
  example_ok:  <EXEMPLO CORRETO ou null>,
  tags:        <TAGS como string separada por vírgula>
})
```

---

## Passo 5 — Confirmar resultado

**Sucesso:**
> "✅ Aprendizado #<ID> registrado e disponível para todos os devs agora via searchKnowledge."

**Falha (isError: true ou exception):**
> "⚠️ Não foi possível registrar o feedback: <motivo>.
> O rascunho foi preservado abaixo para você copiar manualmente se precisar:"
>
> [exibir rascunho completo]
