'use strict';
// SessionStart hook: injeta o catalogo de skills Fluig.
// Catalogo gerado dinamicamente do frontmatter de skills/*/SKILL.md —
// nao ha lista hardcoded para manter. Ver session-context-lib.cjs.
const path = require('path');
const emitSessionContext = require(path.join(__dirname, 'session-context-lib.cjs'));

emitSessionContext({
  pluginRoot: path.resolve(__dirname, '..'),
  namespace: 'fluig',
  title: 'Fluig',
  profile: 'internal',
  cleanupTbcDbs: false,
  groups: [
    { title: 'Ciclo de desenvolvimento (nesta ordem)', names: ['init-project', 'arqueologia', 'brainstorm', 'plan', 'implement', 'deploy', 'qa', 'verify'] },
    { title: 'Scaffolding', names: ['widget', 'dataset', 'form', 'workflow'] },
    { title: 'Qualidade e apoio', names: ['review', 'test', 'test-web', 'debug', 'api-ref', 'feedback', 'base'] },
  ],
  notes: [
    'MCP tools disponiveis: searchKnowledge (padroes/convencoes, use platform: "fluig") + ragSearchKnowledge, ragSearchDocs (busca semantica) — plugin fluig tbc-knowledge',
    'Regra de modelos: opus para brainstorm/design, sonnet para implementacao e review/QA, haiku somente para deploy/compilacao.',
  ],
});
