# q110-18: Render a chart's manifests without installing

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-18-helm-template-dry-run`

`setup.sh` staged a local Helm chart named `render-only` at
`questions/helm-crds/q110-18-helm-template-dry-run/chart` (relative to `practice-bank/`). The
chart is not installed anywhere and has no other consumer - its `templates/deployment.yaml`
hardcodes a container named `payload-runner`.

Without installing the chart, render its manifests locally with a release name of `preview`
(for example `helm template preview questions/helm-crds/q110-18-helm-template-dry-run/chart`)
and read the container name from the rendered output. Then create a ConfigMap named
`rendered-info` in namespace `q110-18-helm-template-dry-run` with a key `containerName` set to
the container name you found (`payload-runner`).

Do **not** run `helm install` - the chart must remain uninstalled, and no Deployment should
exist in the namespace afterward.

## Hint

Search kubernetes.io/docs for **"helm template"** - the Helm CLI reference explains how to
locally render a chart's manifests to stdout without creating a release, which is the
recommended way to preview output before installing.
