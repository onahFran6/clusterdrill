# q110-58: Render manifests with zero contact with the cluster's API server

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-58-helm-template-zero-cluster-contact`

`setup.sh` staged a local chart named `payloadapp` on disk at
`questions/helm-crds/q110-58-helm-template-zero-cluster-contact/chart` (relative to the repo
root). Its `values.yaml` defaults are `replicaCount: 2` and `workerImage: busybox:1.36`. The
last two attempts to install this chart both failed during manifest parsing, so before trying
again against the live cluster, the exact YAML Kubernetes would receive needs to be inspected
first - computed from the chart plus override values, with **zero risk of mutating or even
contacting the cluster's API server** (`helm install --dry-run` still reaches the API server
for validation; that's not good enough here).

Using release name `renderjob`, render the chart with `replicaCount` overridden to `4`, and
save the full rendered manifests to
`~/practice-work/q110-58-helm-template-zero-cluster-contact/rendered.yaml`. Nothing from this
chart should be installed - no release, no Deployment - only the rendered file on disk.

## Hint

Search helm.sh/docs for **"helm template"** - the command reference explains why `helm
template` is the only render path that never talks to the Kubernetes API server at all, unlike
`helm install --dry-run`, which still validates against a live cluster.
