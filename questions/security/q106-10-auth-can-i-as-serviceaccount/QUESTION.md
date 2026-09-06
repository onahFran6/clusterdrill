# q106-10: Check another identity's permissions with `kubectl auth can-i --as`

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-10-auth-can-i-as-serviceaccount`

`setup.sh` already created, in namespace `q106-10-auth-can-i-as-serviceaccount`:

- a ServiceAccount named `ci-deployer`
- a Role named `deployment-editor` (grants `create`/`update` on `deployments`)
- a RoleBinding already granting that Role to `ci-deployer`

Before trusting a CI pipeline with this identity, verify what it can actually do without
switching kubeconfig context. Using `kubectl auth can-i --as`, check whether `ci-deployer` can
`delete` `deployments` in this namespace, then record the literal answer (`yes` or `no`) as the
value of key `answer` in a ConfigMap named `delete-check` in this namespace.

## Hint

Search kubernetes.io/docs for **"kubectl auth can-i"** - the `kubectl` reference book covers the
`--as=system:serviceaccount:<namespace>:<name>` impersonation form used to check as a different
identity than your own.
