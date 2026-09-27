# q110-33-helm-set-string-flag: Force a value to stay a string so a template's truthiness check flips

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-33-helm-set-string-flag`

A local Helm chart named `flagger` is on disk at
`questions/helm-crds/q110-33-helm-set-string-flag/chart` (relative to `practice-bank/`). It
templates a ConfigMap whose `status` key comes from
`{{ if .Values.legacyMode }}enabled{{ else }}disabled{{ end }}`. Do not change that template.

Install the chart into this namespace as release `demo`, supplying `legacyMode` as the string
`"false"` (keep it a string - do not let install-time type parsing turn it into a boolean). The
resulting ConfigMap `demo-flagger` must have `status: enabled`.

## Hint

Search kubernetes.io/docs for **"helm set-string"** - the Helm install command reference
documents `--set-string` as a variant of `--set` that skips YAML/Go type inference entirely,
always treating its value as a string - exactly what's needed here, since a plain `--set` would
silently convert `false` into the boolean type instead of preserving it as text.
