---
name: test
description: Gera e orienta execução de testes UNITÁRIOS para artefatos TOTVS Fluig — widget Angular (runner do projeto) e dataset/evento server-side (harness Node + fluig-mock, sem servidor). Para E2E no servidor real (roteiro, evidências, specs de regressão), use /fluig:test-web.
---

Você vai ajudar a criar e executar testes para artefatos Fluig.

Esta skill cobre os testes **unitários** (sem servidor):
- **Unit de widget** (runner do projeto Angular): componentes, services e pipes
- **Unit server-side** (harness Node do plugin): datasets `ds_*`, eventos `wf_*` e eventos de
  form — o fonte roda inalterado no Node (Rhino é ECMA 5, subconjunto do Node)

**E2E no servidor real é da `/fluig:test-web`** (roteiro aprovado, evidências,
specs de regressão com JUnit) — não gere configuração E2E por aqui.

---

## Unit server-side — dataset e eventos (harness Node, sem servidor)

O motor server-side do Fluig é **Rhino, ECMA 5** — e ES5 é subconjunto do que o Node
executa. O harness do plugin carrega o fonte `ds_*.js`/`wf_*.js` **sem alterar nada**
num contexto com os globais Fluig mockados, e o `node --test` (nativo, zero dependência,
Node 22+) dá o gate mecânico.

Ciclo: identifique o alvo (função de regra pura primeiro — a `/fluig:clean-architecture`
já exige regra de negócio separada de `hAPI`/`DatasetFactory`) → casos feliz, borda e
erro de infra → escreva o teste com o harness:

```js
const test = require('node:test');
const assert = require('node:assert');
const { carregar } = require('${CLAUDE_PLUGIN_ROOT}/skills/test/assets/fluig-mock.cjs');

test('createDataset devolve linha estruturada', () => {
  const ctx = carregar('./datasets/ds_meu.js');
  const ds = ctx.createDataset(null, [], null);
  assert.deepEqual(ds.rows, [['001', true]]);   // deepEqual, NUNCA deepStrictEqual
});

test('falha de infra não vaza exceção', () => {
  const ctx = carregar('./datasets/ds_meu.js', {
    DatasetFactory: { getDataset: () => { throw new Error('offline'); } }
  });
  // conforme o contrato do fonte: linha de erro estruturada, ou throw esperado
});
```

Gate mecânico (executado pelo orquestrador — self-report não aprova):

```bash
mkdir -p logs
node --test --test-reporter=junit --test-reporter-destination=logs/fluig-unit.xml \
     --experimental-test-coverage --test-coverage-lines=70 \
     --test-coverage-include='**/ds_*.js' --test-coverage-include='**/wf_*.js' \
     --test-coverage-include='**/events/**' 'testes/**/*.test.js'
```

Critério: exit code 0 **e** `fail 0` no XML — **e** a checagem de existência abaixo.

**Checagem de existência (a cobertura NÃO faz isso):** arquivo que nenhum teste
carrega é **invisível** para o relatório — dataset novo sem um único teste passa o
threshold verde. Antes de aprovar, confira um a um: **todo `ds_*`/`wf_*`/evento tocado
pela task tem arquivo de teste correspondente em `testes/`**. Fonte sem teste = gate
vermelho, independente do percentual.

**Quatro armadilhas (não ignore):**
1. O harness passa `filename` **absoluto** ao `vm` — com caminho relativo o fonte some
   do relatório de cobertura em silêncio.
2. Compare linhas com `assert.deepEqual`, nunca `deepStrictEqual` — os arrays nascem
   dentro do `vm`, em outro realm, e o strict falha com conteúdo idêntico.
3. O threshold **só morde com `--test-coverage-include`** apontando para os fontes —
   sem o include, mock e teste (100%) diluem a média. Use padrões **desancorados**
   (`'**/ds_*.js'`, `'**/events/**'`): evento de form mora em
   `formularios/<form>/events/`, e `'events/**'` ancorado na raiz não o alcança.
4. `mkdir -p logs` antes: com o diretório inexistente o Node aborta no reporter antes
   de rodar teste algum; e o argumento posicional precisa ser glob de arquivos
   (`'testes/**/*.test.js'`), não diretório.

**Limite de fidelidade, dito em voz alta:** o Node valida a **lógica**, não o Rhino.
Interop Java (`java.*`, `java.lang.String` retornado por `hAPI`/`getValue`) pode divergir —
isso só o teste de integração pós-deploy no `/fluig:qa` pega. O harness não substitui o QA;
o QA não substitui o harness.

---

## Unit de widget — runner do PROJETO (nunca fixe)

O runner vem do projeto, não do plugin: leia `angular.json` e `package.json` antes de
gerar qualquer spec ou comando.

- **Builder atual** (`@angular/build:unit-test`): o default é **vitest**, com `karma`
  suportado via `--runner`. Gate: `ng test` com `--reporters junit` + `coverageThresholds`
  no `angular.json` (o comando falha sozinho abaixo do limite).
- **Projeto legado com `karma.conf.js`:** mantenha Karma. Se não houver
  `coverageReporter.check`, copie o template do plugin — ele transforma a cobertura em
  gate mecânico (`npm test` falha sozinho abaixo de 70%):

```bash
cp ${CLAUDE_PLUGIN_ROOT}/skills/test/assets/karma.conf.template.js ./karma.conf.js
npm test -- --watch=false --browsers=ChromeHeadless --code-coverage
node -e "const c=require('./coverage/coverage-summary.json').total; console.log(JSON.stringify(c.lines))"
```

Leia o resumo de cobertura do arquivo (não aceite auto-relato). Templates de spec:
consulte a referência via MCP:
```
searchKnowledge({ platform: "fluig", skill: "fluig-test", keyword: "unit tests" })
```

---

## E2E — vá para `/fluig:test-web`

E2E contra o servidor real saiu desta skill: o protocolo completo (roteiro aprovado
pelo team leader, screenshots por passo em `evidencias/`, critério verificável
literal, tratamento de erro com log do servidor, spec de regressão com
`--reporter=junit`) vive na **`/fluig:test-web`**. As restrições permanecem lá:
servidor real (nunca `localhost`), artefato publicado, credenciais por variável de
ambiente.

---

## Regras Obrigatórias

- `coverage/` nunca commitado
- Usuário e senha via variáveis de ambiente, nunca hardcoded
- Todos os specs devem cobrir casos de erro
- E2E requer deploy prévio

---

## Consulta de Conhecimento

Se precisar de informação não disponível no MCP, consulte o RAG:
```
ragSearchKnowledge({ query: "<termo relevante>" })
```
