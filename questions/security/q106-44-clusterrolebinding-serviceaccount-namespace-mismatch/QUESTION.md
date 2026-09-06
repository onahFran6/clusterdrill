# q106-44: Fix a ClusterRoleBinding pointing at the wrong subject namespace

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-44-clusterrolebinding-serviceaccount-namespace-mismatch`

`setup.sh` already created, in this namespace, a ServiceAccount named `deployer`, a ClusterRole
named `q106-44-deployment-manager` (grants `get`/`list`/`create`/`update` on `deployments`
cluster-wide), and a ClusterRoleBinding named `q106-44-deployer-binding` that binds them together -
but its subject's `namespace` field was copy-pasted from a different manifest and still says
`default`, so it never actually applies to this namespace's `deployer` ServiceAccount. Fix the
binding's subject so `deployer` (in this namespace) gets the grant, without changing the
ClusterRole or creating a new binding.

## Hint

Search kubernetes.io/docs for **"referring to subjects"** - the RBAC reference page shows that a
`ServiceAccount` subject must specify the exact `namespace` it lives in for the binding to apply.
