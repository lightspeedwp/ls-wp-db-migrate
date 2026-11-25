module.exports = [
  {
    ignores: [
      'node_modules/',
      'coverage/',
      'dist/',
      'build/',
      '.git/',
      '__tests__/coverage/',
      'jest.config.js',
      '.yamllint.config.cjs',
      '*.yml',
      '*.yaml',
    ],
  },
  {
    files: ['**/*.js', '**/*.cjs', '**/*.mjs'],
    languageOptions: {
      ecmaVersion: 2020,
      sourceType: 'module',
      globals: {
        console: 'readonly',
        process: 'readonly',
      },
    },
    // Formatting (indentation, quotes, semicolons, commas) is left to Prettier.
    rules: {
      'no-unused-vars': ['error', { argsIgnorePattern: '^_', varsIgnorePattern: '^_' }],
      'no-console': 'off',
      'prefer-const': 'warn',
      eqeqeq: ['error', 'always'],
      curly: ['error', 'all'],
    },
  },
];
