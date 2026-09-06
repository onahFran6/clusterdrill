# q110-44-helm-required-function-value: Supply a value a chart's `required` function demands

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-44-helm-required-function-value`

`setup.sh` staged a local Helm chart named `gateway` on disk at
`questions/helm-crds/q110-44-helm-required-function-value/chart` (relative to the
`practice-bank/` directory). Its Secret template calls Helm's `required` function on
`.Values.apiKey`:

```
apiKey: {{ required "apiKey is required - pass --set apiKey=..." .Values.apiKey | quote }}
```

`apiKey` defaults to an empty string in `values.yaml`, so installing this chart as-is fails
outright at template-render time (before anything is even sent to the cluster) with the
`required` function's own error message - no Secret, no release, nothing partially created.

Install this chart into namespace `q110-44-helm-required-function-value` under
release name `demo`, supplying `apiKey` as `sk-live-92f3` via `--set` so the `required` check
passes and the Secret is actually created.

## Hint

Search kubernetes.io/docs for **"helm required function"** - the Helm Chart Template Guide's
Functions and Pipelines section documents `required` as a template function that aborts
rendering entirely (with a custom message you control) when the value it's given is empty,
letting a chart demand a value up front instead of silently deploying with a blank one.
