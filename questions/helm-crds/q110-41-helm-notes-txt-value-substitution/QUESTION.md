# q110-41-helm-notes-txt-value-substitution: Install a chart whose NOTES.txt echoes back a value you set

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-41-helm-notes-txt-value-substitution`

`setup.sh` staged a local Helm chart named `onboarder` on disk at
`questions/helm-crds/q110-41-helm-notes-txt-value-substitution/chart` (relative to the
`practice-bank/` directory). The chart's `templates/NOTES.txt` renders
`Deployed {{ .Values.appName }} version {{ .Chart.AppVersion }}` - post-install guidance text
Helm stores with the release and prints after install (retrievable later with
`helm get notes`).

Install this chart into namespace `q110-41-helm-notes-txt-value-substitution` under release name
`demo`, setting `appName` to `payments-api`. Afterward, `helm get notes demo -n
q110-41-helm-notes-txt-value-substitution` must show the line `Deployed payments-api version
1.0` (the chart's `appVersion` is fixed at `1.0`).

## Hint

Search kubernetes.io/docs for **"helm NOTES.txt"** - the Helm Chart Template Guide's "Creating a
NOTES.txt File" section shows that `templates/NOTES.txt` is rendered through the same template
engine as every other chart file, with the result stored on the release and retrievable with
`helm get notes <release>`.
