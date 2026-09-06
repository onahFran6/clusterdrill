import globals from "globals";

export default [
  {
    files: ["web/static/*.js"],
    languageOptions: {
      ecmaVersion: 2022,
      sourceType: "script",
      globals: {
        ...globals.browser,
        // Loaded from a CDN <script> tag in question.html, not a module
        // import - see web/templates/question.html.
        mermaid: "readonly",
      },
    },
    rules: {
      "no-unused-vars": "warn",
      "no-undef": "error",
      eqeqeq: "warn",
      "no-var": "warn",
    },
  },
];
