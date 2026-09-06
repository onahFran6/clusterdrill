# q110-40-helm-chart-local-subchart-dependency: Pull in a local subchart dependency and install both

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-40-helm-chart-local-subchart-dependency`

`setup.sh` staged two local Helm charts on disk, both relative to the `practice-bank/`
directory:

- a subchart named `cache` at
  `questions/helm-crds/q110-40-helm-chart-local-subchart-dependency/chart-cache` (templates a
  ConfigMap)
- a parent chart named `webapp` at
  `questions/helm-crds/q110-40-helm-chart-local-subchart-dependency/chart`, whose `Chart.yaml`
  declares a dependency on `cache` via a local `file://../chart-cache` repository - but that
  dependency has **not been fetched yet**: there is no `charts/` directory inside the parent
  chart, so installing it as-is would only apply the parent's own Deployment, not the
  subchart's ConfigMap.

Run `helm dependency update` inside the parent chart directory to fetch the local subchart into
its `charts/` subdirectory, then install it into namespace
`q110-40-helm-chart-local-subchart-dependency` under release name `demo`. Both the parent's
Deployment (`demo-webapp`) and the subchart's ConfigMap (`demo-cache`) must exist afterward.

## Hint

Search kubernetes.io/docs for **"helm chart dependencies"** - the Helm Charts Guide's
Dependencies section shows a `dependencies:` block in `Chart.yaml` (including a `file://` local
path as a valid `repository` value, needing no network access) and the `helm dependency update`
command that resolves it into the chart's `charts/` subdirectory before install.
