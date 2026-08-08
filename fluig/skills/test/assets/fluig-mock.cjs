// fluig-mock.cjs — contexto de execução para testar datasets/eventos Fluig (Rhino/ES5) no Node.
// Uso: const { carregar } = require('<plugin>/skills/test/assets/fluig-mock.cjs');
//       const ctx = carregar('./datasets/ds_meu.js');            // globais padrão
//       const ds  = ctx.createDataset(null, [], null);
//       const ctx2 = carregar('./datasets/ds_meu.js', {          // override por teste
//         DatasetFactory: { getDataset: () => { throw new Error('offline'); } }
//       });
//
// Regras aprendidas no protótipo (não remova):
// - filename ABSOLUTO no vm — com caminho relativo o fonte some do relatório de cobertura.
// - Nos testes, compare linhas com assert.deepEqual (não deepStrictEqual): arrays nascem
//   dentro do vm, em outro realm, e o strict falha com conteúdo idêntico.
// - Gate de cobertura: node --test --experimental-test-coverage --test-coverage-lines=70
//   --test-coverage-include='datasets/**' — sem o include, mock e teste diluem a média.

'use strict';
const vm = require('node:vm');
const fs = require('node:fs');
const path = require('node:path');

function newDataset() {
  const columns = [];
  const rows = [];
  return {
    // lado de escrita (o fonte preenche)
    addColumn: (c) => columns.push(c),
    addRow: (r) => rows.push(r),
    columns,
    rows,
    // lado de leitura (o fonte consome o retorno de DatasetFactory.getDataset):
    // API clássica do Fluig — rowsCount + getValue(linha, coluna)
    get rowsCount() { return rows.length; },
    getValue(i, col) {
      const j = typeof col === 'number' ? col : columns.indexOf(col);
      return rows[i] ? rows[i][j] : undefined;
    },
  };
}

function makeContext(overrides = {}) {
  const logHistory = [];
  const mklog = (level) => (msg) => logHistory.push({ level, msg: String(msg) });
  const base = {
    // Dataset
    DatasetBuilder: { newDataset },
    DatasetFactory: {
      getDataset: () => newDataset(),
      createConstraint: (field, initial, final, type) => ({ field, initial, final, type }),
      createDataset: () => newDataset(),
    },
    ConstraintType: { MUST: 'MUST', SHOULD: 'SHOULD', MUST_NOT: 'MUST_NOT' },
    DatasetError: function DatasetError(msg) { this.message = String(msg); },
    // Log — silencioso, com histórico consultável nos testes (ctx.__log)
    log: { info: mklog('info'), warn: mklog('warn'), error: mklog('error'), debug: mklog('debug') },
    __log: logHistory,
    // Form / workflow
    getValue: () => '',
    hAPI: {
      getCardValue: () => '',
      setCardValue: () => {},
      setTaskComments: () => {},
      getUserLogin: () => 'tester',
    },
    // Interop Java mínima — ATENÇÃO: mock valida a LÓGICA, não o Rhino real.
    // Divergência de interop (java.lang.String etc.) só aparece no servidor.
    java: { util: { Date } },
    JSON,
  };
  return vm.createContext(Object.assign(base, overrides));
}

// Carrega o fonte ds_/wf_/evento SEM alterar nada (ES5 é subconjunto do Node)
// e devolve o contexto — chame ctx.createDataset(...), ctx.<evento>(...) direto.
function carregar(arquivo, overrides) {
  const ctx = makeContext(overrides);
  vm.runInContext(fs.readFileSync(arquivo, 'utf8'), ctx, {
    filename: path.resolve(arquivo), // absoluto — obrigatório para a cobertura
  });
  return ctx;
}

module.exports = { carregar, makeContext, newDataset };
