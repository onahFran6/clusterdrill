# q110-01: Install a Helm chart under a specific release name

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-01-helm-install-release`

`setup.sh` staged a local Helm chart named `greeter` on disk at
`questions/helm-crds/q110-01-helm-install-release/chart` (relative to the `practice-bank/`
directory). The chart templates a single-replica Deployment.

Install this chart into namespace `q110-01-helm-install-release` under the release name
`hello-app`. Do not change any values - install with the chart's defaults.

## Hint

Search kubernetes.io/docs for **"helm install"** - the Helm quickstart shows the exact
`helm install <release-name> <chart>` syntax, including how to target a specific namespace.

