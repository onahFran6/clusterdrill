# q110-18: Render a chart's manifests without installing

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-18-helm-template-dry-run`

A local Helm chart named `render-only` is available at
`$HOME/practice-work/q110-18-helm-template-dry-run/chart`. The
chart is not installed anywhere - its templates include a Deployment with a container whose
name you must discover from the rendered output.

Without installing the chart, render its manifests locally with release name `preview` and
read the container name from the rendered output. Then create a ConfigMap named
`rendered-info` in namespace `q110-18-helm-template-dry-run` with a key `containerName` set to
the container name you found.

Do not run `helm install` - the chart must remain uninstalled, and no Deployment should exist
in the namespace afterward.

## Hint

Search kubernetes.io/docs for **"helm template"** - the Helm CLI reference explains how to
locally render a chart's manifests to stdout without creating a release (for example
`helm template preview $HOME/practice-work/q110-18-helm-template-dry-run/chart`), which is the
recommended way to preview output before installing.
