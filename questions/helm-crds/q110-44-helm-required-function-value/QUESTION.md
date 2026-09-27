# q110-44-helm-required-function-value: Supply a value a chart's `required` function demands

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-44-helm-required-function-value`

A local Helm chart named `gateway` is on disk at
`questions/helm-crds/q110-44-helm-required-function-value/chart` (relative to `practice-bank/`).
Its Secret template calls Helm's `required` function on `.Values.apiKey`. Installing with the
chart defaults fails at template-render time.

Install the chart into this namespace as release `demo`, supplying `apiKey` as `sk-live-92f3` so
the `required` check passes and the Secret is created.

## Hint

Search kubernetes.io/docs for **"helm required function"** - the Helm Chart Template Guide's
Functions and Pipelines section documents `required` as a template function that aborts
rendering entirely (with a custom message you control) when the value it's given is empty,
letting a chart demand a value up front instead of silently deploying with a blank one.
