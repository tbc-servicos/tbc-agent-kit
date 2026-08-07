# Template: Dispatch protheus-implementer

Use este template ao despachar o teammate `protheus-implementer` via SendMessage.

## Prompt

```
Implemente a seguinte task do plano:

## Task
{TASK_TEXT}

## Design Doc
{DESIGN_DOC_CONTENT}

## Contexto
- Módulo: {MODULO}
- Tabelas: {TABELAS}
- Regras de negócio: {REGRAS}
- Dependências: {DEPENDENCIAS}

## Instruções
1. Consulte o MCP para convenções e templates antes de codificar
2. Siga TDD: implemente → lint → auto-review
3. Não crie fonte (.prw/.tlpp) que não esteja nesta task. A lista de fontes do
   plano é fechada. Se achar que falta um, reporte BLOCKED com o motivo — fonte
   novo é decisão de design e volta ao /protheus:brainstorm.
   Classes coesas do mesmo papel e contexto ficam no MESMO fonte (TLPP aceita
   mais de uma classe por arquivo); só divida quando mudarem por motivos
   diferentes ou o fonte passar de ~800 linhas.
4. Reporte DONE, BLOCKED ou NEEDS_CONTEXT ao final
```
