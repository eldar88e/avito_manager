import js from "@eslint/js";
import prettier from "eslint-plugin-prettier";
import importPlugin from "eslint-plugin-import";

/** @type {import('eslint').Linter.FlatConfig[]} */
export default [
    js.configs.recommended,
    {
      files: ["app/frontend/**/*.{js,jsx,ts,tsx}"],
      languageOptions: {
        parserOptions: {
          ecmaVersion: "latest",
          sourceType: "module"
        },
        globals: {
          window: "readonly",
          document: "readonly",
          navigator: "readonly",
          localStorage: "readonly",
          sessionStorage: "readonly",
          confirm: "readonly",
          alert: "readonly",
          console: "readonly",
          setTimeout: "readonly",
          setInterval: "readonly",
          clearTimeout: "readonly",
          clearInterval: "readonly",
          Image: "readonly",
          closeModal: "readonly",
          openModal: "readonly",
          ymaps: "readonly", // если используешь Яндекс.Карты
        },
      },
      plugins: {
        prettier,
        import: importPlugin
      },
      rules: {
        "prettier/prettier": "error",

        // Упорядочивание импорта
        "import/order": [
          "warn",
          {
            groups: ["builtin", "external", "internal", "parent", "sibling", "index"],
            "newlines-between": "always"
          }
        ],

        // Игнорировать аргументы начинающиеся с _
        "no-unused-vars": ["warn", { argsIgnorePattern: "^_" }]
      }
    }
];
