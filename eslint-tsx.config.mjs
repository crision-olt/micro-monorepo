import tsConfig from "./eslint-ts.config.mjs";
import reactPlugin from "eslint-plugin-react";
import reactHooksPlugin from "eslint-plugin-react-hooks";
import tsParser from "@typescript-eslint/parser";

/** @type {import('eslint').Linter.Config[]} */
export default [
  ...tsConfig.map((config) => ({
    ...config,
    files: ["**/*.tsx"],
    languageOptions: {
      ...config.languageOptions,
      parser: tsParser,
      parserOptions: {
        ...(config.languageOptions?.parserOptions ?? {}),
        project: true,
        ecmaFeatures: { jsx: true },
      },
    },
  })),
  {
    files: ["**/*.tsx"],
    plugins: {
      react: reactPlugin,
      "react-hooks": reactHooksPlugin,
    },
    rules: {
      ...reactPlugin.configs.recommended.rules,
      ...reactHooksPlugin.configs.recommended.rules,
      "react/react-in-jsx-scope": "off",
      "react/prop-types": "off",
    },
    settings: {
      react: { version: "detect" },
    },
  },
];
