# q110-38-crd-instance-label-selector-list: List only one tier of custom resource instances by label

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-38-crd-instance-label-selector-list`

`setup.sh` already registered a CustomResourceDefinition `fleetnodes.fleet.clusterdrill.io`
(kind `FleetNode`, plural `fleetnodes`, group `fleet.clusterdrill.io/v1`, namespaced) and
created three
instances in namespace `q110-38-crd-instance-label-selector-list`, each labeled `tier: edge` or
`tier: core`:

- `node-a` (`tier: edge`)
- `node-b` (`tier: core`)
- `node-c` (`tier: edge`)

Using a label selector (`kubectl get ... -l ...`), list only the `tier: edge` instances and save
their names, one per line and sorted alphabetically, to a file at
`~/practice-work/q110-38-crd-instance-label-selector-list/edge-nodes.txt`.

## Hint

Search kubernetes.io/docs for **"kubectl get" "selector"** - the kubectl command reference shows
`-l`/`--selector` filtering any resource list (built-in or custom) by label, exactly the way it
filters Pods or Deployments.
