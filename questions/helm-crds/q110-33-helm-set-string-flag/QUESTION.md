# q110-33-helm-set-string-flag: Force a value to stay a string so a template's truthiness check flips

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-33-helm-set-string-flag`

`setup.sh` staged a local Helm chart named `flagger` on disk at
`questions/helm-crds/q110-33-helm-set-string-flag/chart` (relative to the `practice-bank/`
directory). The chart templates a ConfigMap whose `status` key is set by
`{{ if .Values.legacyMode }}enabled{{ else }}disabled{{ end }}`.

An upstream config-management tool always emits `legacyMode` as the literal string `"false"`,
never a real boolean - and in Go templates, **any non-empty string is truthy**, including the
string `"false"`. So when this chart receives `legacyMode` as the string `"false"`, its `status`
must render as `enabled`, not `disabled` - the opposite of what the value's English meaning
suggests, but the chart's actual (already-existing, not-to-be-changed) template logic.

Install this chart into namespace `q110-33-helm-set-string-flag` under release name `demo`,
setting `legacyMode` to the **string** `"false"` using `--set-string` (a plain `--set
legacyMode=false` would auto-parse the value into the real boolean `false` instead, which the
same `if` treats as falsy - producing `status: disabled`, the wrong result for this task).

## Hint

Search kubernetes.io/docs for **"helm set-string"** - the Helm install command reference
documents `--set-string` as a variant of `--set` that skips YAML/Go type inference entirely,
always treating its value as a string - exactly what's needed here, since a plain `--set` would
silently convert `false` into the boolean type instead of preserving it as text.
