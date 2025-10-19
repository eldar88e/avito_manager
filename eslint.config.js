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
          fetch: "readonly",
          window: "readonly",
          document: "readonly",
          confirm: "readonly",
          alert: "readonly",
          console: "readonly",
          localStorage: "readonly",
          sessionStorage: "readonly",
          HTMLMetaElement: "readonly",
          URLSearchParams: "readonly",
          FileReader: "readonly",
          IntersectionObserver: "readonly",
          navigator: "readonly",
          CustomEvent: "readonly",
          setTimeout: "readonly",
          setInterval: "readonly",
          clearTimeout: "readonly",
          clearInterval: "readonly",
          closeModal: "readonly",
          openModal: "readonly",
        },
      },
      plugins: {
        prettier,
        import: importPlugin
      },
      rules: { "prettier/prettier": "error" },
      settings: {
        react: {
          version: "detect"
        }
      }
    }
];
