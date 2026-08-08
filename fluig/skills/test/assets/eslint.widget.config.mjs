// ESLint flat config — fallback para WIDGET Angular/TypeScript quando o projeto não tem
// config próprio. Projeto com angular-eslint configurado usa o do projeto (este NÃO substitui).
// Convenção OPOSTA ao server-side: aqui é ES moderno (const/let), lá é ES5/var.
export default [
  {
    files: ['**/*.ts'],
    languageOptions: {
      ecmaVersion: 'latest',
      sourceType: 'module',
    },
    rules: {
      'no-alert': 'error',          // sempre Swal.fire(), nunca alert() (CLAUDE.md do plugin)
      'no-empty': 'error',          // catch vazio proibido
      'no-eval': 'error',
      'no-var': 'error',
      'prefer-const': 'warn',
      eqeqeq: ['error', 'smart'],
    },
  },
];
