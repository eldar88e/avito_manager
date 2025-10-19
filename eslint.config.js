import js from "@eslint/js";
import prettier from "eslint-plugin-prettier";
import importPlugin from "eslint-plugin-import";

/** @type {import('eslint').Linter.FlatConfig[]} */
export default [
    js.configs.recommended,
    {
      files: ["app/frontend/**/*.{js}"],
      languageOptions: {
        parser: "@babel/eslint-parser",
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
      plugins: ["prettier", "import"],
      rules: { "prettier/prettier": "error" },
      settings: {
        react: {
          version: "detect"
        }
      }
    }
];
