# q110-41-helm-notes-txt-value-substitution: Install a chart whose NOTES.txt echoes back a value you set

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-41-helm-notes-txt-value-substitution`

A local Helm chart named `onboarder` is on disk at
`questions/helm-crds/q110-41-helm-notes-txt-value-substitution/chart` (relative to
`practice-bank/`). Its `templates/NOTES.txt` renders
`Deployed {{ .Values.appName }} version {{ .Chart.AppVersion }}` (retrievable later with
`helm get notes`).

Install the chart into this namespace as release `demo`, setting `appName` to `payments-api`.
Afterward, `helm get notes demo` in this namespace must show
`Deployed payments-api version 1.0` (the chart's `appVersion` is `1.0`).

## Hint

Search kubernetes.io/docs for **"helm NOTES.txt"** - the Helm Chart Template Guide's "Creating a
NOTES.txt File" section shows that `templates/NOTES.txt` is rendered through the same template
engine as every other chart file, with the result stored on the release and retrievable with
`helm get notes <release>`.
