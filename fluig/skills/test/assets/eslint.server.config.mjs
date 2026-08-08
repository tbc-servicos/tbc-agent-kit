// ESLint flat config — JavaScript SERVER-SIDE do Fluig (datasets ds_*, eventos wf_*, events/).
// O motor do Fluig é Rhino, ECMA 5: ecmaVersion 5 faz let/const/arrow/class virarem ERRO DE
// PARSE aqui, antes do deploy — que é exatamente onde quebrariam no servidor.
// Uso standalone: npx eslint --config <plugin>/skills/test/assets/eslint.server.config.mjs <arquivo.js>
export default [
  {
    // datasets/** e workflow/** cobrem fonte fora da convenção de prefixo ds_/wf_ —
    // arquivo fora de TODOS os padrões fica SEM regra (flat config): avise o dev que
    // nome fora da convenção sai do gate
    files: ['**/ds_*.js', '**/wf_*.js', '**/events/**/*.js', '**/Util/**/*.js', '**/datasets/**/*.js', '**/workflow/**/*.js'],
    languageOptions: {
      ecmaVersion: 5,
      sourceType: 'script',
      globals: {
        // Dataset
        DatasetBuilder: 'readonly',
        DatasetFactory: 'readonly',
        ConstraintType: 'readonly',
        DatasetError: 'readonly',
        // entry points (defineStructure, createDataset, onSync, eventos wf_) NÃO entram
        // aqui: são DEFINIDOS pelo fonte — declará-los como global dispara no-redeclare
        addColumn: 'readonly',
        addRow: 'readonly',
        // Workflow / form
        hAPI: 'readonly',
        getValue: 'readonly',
        setValue: 'readonly',
        log: 'readonly',
        fluigAPI: 'readonly',
        // Interop Java (Rhino)
        java: 'readonly',
        javax: 'readonly',
        Packages: 'readonly',
        JSON: 'readonly',
      },
    },
    rules: {
      'no-undef': 'error',       // global fora da lista = digitação errada ou API inventada
      'no-empty': 'error',       // catch vazio proibido (convenção do plugin)
      'no-eval': 'error',
      'no-implied-eval': 'error',
      'no-alert': 'error',
      // vars:'local' — função top-level é entry point da engine (createDataset,
      // eventos wf_), não conta como "não usada"; variável local morta continua warning
      'no-unused-vars': ['warn', { args: 'none', vars: 'local' }],
      'no-redeclare': 'error',
      eqeqeq: ['warn', 'smart'],
    },
  },
];
