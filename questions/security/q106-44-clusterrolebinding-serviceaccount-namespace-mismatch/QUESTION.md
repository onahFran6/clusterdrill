# q106-44: Fix a ClusterRoleBinding pointing at the wrong subject namespace

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-44-clusterrolebinding-serviceaccount-namespace-mismatch`

This namespace already has a ServiceAccount named `deployer`, a ClusterRole named
`q106-44-deployment-manager` (grants `get`/`list`/`create`/`update` on `deployments`
cluster-wide), and a ClusterRoleBinding named `q106-44-deployer-binding` that binds them
together. The binding does not grant permissions to this namespace's `deployer` ServiceAccount.

Fix that binding's subject so `deployer` in this namespace receives the grant. Do not change the
ClusterRole, and do not create a new binding.

## Hint

Search kubernetes.io/docs for **"referring to subjects"** - the RBAC reference page shows that a
`ServiceAccount` subject must name the namespace the account actually lives in. The binding's
subject namespace is still `default`, which does not match this question's namespace.
