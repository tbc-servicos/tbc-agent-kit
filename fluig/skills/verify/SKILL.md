---
name: verify
description: Gate de deploy final para artefatos Fluig. Checklist adaptativo baseado no ambiente do projeto (HML vs servidor único). Acione após fluig-review aprovado, antes de declarar o artefato pronto para produção. Confirma ambiente, valida checklist e aciona o deploy final via fluig-deployer.
disable-model-invocation: true
---

Você vai conduzir o gate final antes de declarar um artefato Fluig pronto para produção.

## HARD GATE

- **Leia `docs/fluig/plans/<slug>.gates.json`** e confirme: todas as chaves com
  `status=ok` (as duas metades de `tests_unit` aceitam `n/a` explícito) — cole o
  sumário literal do fluig-qa, não pergunte ao usuário. Não confie em afirmação da
  conversa — o arquivo é a fonte de verdade (pipeline retomável). O `<slug>` é o basename (sem `.md`) do plano salvo pelo `/fluig:plan` em `docs/fluig/plans/`; havendo mais de um `.gates.json`, pergunte ao dev qual feature.

Não acione o deploy final e não declare o artefato "pronto" sem completar o checklist abaixo com todas as respostas positivas.

## Passo 1 — Ler contexto do projeto

Leia o CLAUDE.md do projeto para identificar:
- **Servidor(es):** URL(s) disponíveis e seus ambientes (HML, produção, único)
- **Prefixo do cliente:** para confirmar que os artefatos corretos serão deployados
- **Integração Protheus:** se existir, confirmar que a URL da API está correta

Se o CLAUDE.md não existir no projeto atual, pergunte ao usuário o servidor de destino antes de prosseguir.

## Passo 2 — Checklist adaptativo

### Se o projeto tem ambiente HML (homologação separado de produção):

Use `AskUserQuestion` para confirmar cada item:

1. O `fluig-review` foi executado e retornou aprovado no ambiente HML?
2. Os itens CRÍTICOS da revisão estática estão corrigidos?
3. O deploy será feito em **PRODUÇÃO** (não HML) — confirma o ambiente correto?
4. Há um plano de rollback definido? (qual versão anterior, como reverter via fluig-deployer)
5. O responsável pelo ambiente de produção foi notificado?

### Se o projeto tem servidor único:

Use `AskUserQuestion` para confirmar cada item:

1. O `fluig-review` foi executado e retornou aprovado?
2. Os itens CRÍTICOS da revisão estática estão corrigidos?
3. O fluig-qa não retornou nenhum item de risco ALTO?
4. Há um plano de rollback definido? (backup do artefato anterior)
5. O horário de deploy é adequado? (evitar horário de pico de uso)

**Se qualquer item for respondido negativamente:** não prossiga. Indique o que precisa ser resolvido antes de retomar.

### Regressão do legado (os dois cenários)

- [ ] O cabeçalho do plano tem a linha `**Regressão:**` — apontando para o arquivo
      **ou** com justificativa de "não se aplica". Sem a linha = Passo 3.5 do plan
      foi pulado → **bloqueia**
- [ ] `docs/legado/regressao/<slug>.md` existe e **cada item tem veredito**:
      verificado / não verificado / quebrou — item sem veredito **bloqueia**
- [ ] Item que deixou de valer foi para "Arquivadas" com motivo — não apagado

## Passo 3 — Confirmação final

Apresente um resumo antes do deploy:

```
DEPLOY FINAL — [nome do artefato]

Artefato(s): [listar com nomes completos]
Servidor destino: [URL]
Ambiente: [Produção / Servidor único]
Checklist: ✅ Todos os itens confirmados

Confirma o deploy?
```

Aguarde confirmação explícita do usuário antes de prosseguir ("sim", "confirma" ou "pode deployar").

## Passo 4 — Deploy final (fluig-deployer)

Após confirmação, acione o agente `fluig-deployer`:
> "Faça o deploy dos artefatos [listar] para [URL servidor de produção / servidor único]."

## Passo 5 — Resultado

Após o deploy com sucesso, apresente:

```
DEPLOY CONCLUÍDO — [nome do artefato]

Artefato(s) publicado(s) em: [URL]

Para validar no servidor:
  Acesse [URL do artefato no Fluig] e verifique o comportamento esperado.

Em caso de problema — rollback:
  "use fluig-deployer to rollback [artefato] to previous version"
```

## Passo 5.5 — Writeback: devolver a entrega ao mapa (append-only, não bloqueia)

**Só execute este passo com o deploy do Passo 4 CONCLUÍDO COM SUCESSO** — deploy negado no Passo 3 ou falho no Passo 4 não gera registro nenhum (entrega fantasma no mapa é regra CONFIRMADO falsa, o pior tipo). Com o artefato publicado, devolva o que a entrega mudou — senão o mapa da
`/fluig:arqueologia` envelhece no instante do deploy e o `/fluig:brainstorm` da
próxima demanda ancora o design numa foto velha do ambiente:

1. **Itens novos** em `docs/legado/regressao/<slug>.md` (mesma numeração `W`):
   comportamento que **esta entrega criou** e que outra demanda pode desfazer — só
   CONFIRMADO e com forma de verificar (harness, spec E2E, artefato no servidor).
   Item da lista original que a homologação provou errado vai para "Arquivadas"
   **com o motivo**. Item externo (Protheus, RPA, job) entra com o sistema na Origem.
   O checklist de regressão do Passo 2 (vereditos) continua sendo pré-deploy — este
   passo só ACRESCENTA.
2. **Linha `## Entregas`** no `docs/legado/<fatia>.md`: data, demanda, artefatos
   publicados (dataset/form/workflow/widget + versão), RN novas numeradas
   (`RN-<FATIA>-NN`, CONFIRMADO — o artefato acabou de ser publicado no Passo 4). Fatia sem
   mapa: crie só com o cabeçalho e a seção `## Entregas` — registro de entrega não
   é arqueologia.
3. **`docs/legado/COBERTURA.md`**: ticket da entrega na linha da fatia.

> Entrega que não volta pro mapa é conhecimento que morre no deploy.

## Regras obrigatórias

- Nunca fazer deploy em produção sem confirmação explícita do usuário
- Sempre ler CLAUDE.md para identificar o ambiente correto — nunca assumir
- Se o projeto não tiver CLAUDE.md, perguntar o servidor antes de prosseguir
- Sempre informar como fazer rollback após o deploy
- Checklist HML e servidor único são diferentes — não misturar

---

## Consulta de Conhecimento

Se precisar de informação não disponível no MCP, consulte o RAG:
```
searchKnowledge({ keyword: "<termo relevante>" })
```
