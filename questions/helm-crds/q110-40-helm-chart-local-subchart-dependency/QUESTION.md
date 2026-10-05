# q110-40-helm-chart-local-subchart-dependency: Pull in a local subchart dependency and install both

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-40-helm-chart-local-subchart-dependency`

Two local Helm charts are on disk:

- subchart `cache` at
  `$HOME/practice-work/q110-40-helm-chart-local-subchart-dependency/chart-cache` (templates a
  ConfigMap)
- parent chart `webapp` at
  `$HOME/practice-work/q110-40-helm-chart-local-subchart-dependency/chart`, whose `Chart.yaml`
  declares a dependency on `cache` via `file://../chart-cache` - but the dependency has not been
  fetched yet (no `charts/` directory under the parent)

Resolve the parent's local dependency into its `charts/` subdirectory, then install the parent
into this namespace as release `demo`. Both Deployment `demo-webapp` and ConfigMap `demo-cache`
must exist afterward.

## Hint

Search kubernetes.io/docs for **"helm chart dependencies"** - the Helm Charts Guide's
Dependencies section shows a `dependencies:` block in `Chart.yaml` (including a `file://` local
path as a valid `repository` value, needing no network access) and the `helm dependency update`
command that resolves it into the chart's `charts/` subdirectory before install.
