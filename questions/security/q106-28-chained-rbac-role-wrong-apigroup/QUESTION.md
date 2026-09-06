# q106-28-chained-rbac-role-wrong-apigroup: Fix a Role that grants access to the wrong apiGroup for a Deployment-reading permission

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-28-chained-rbac-role-wrong-apigroup`

`setup.sh` already created, in namespace `q106-28-chained-rbac-role-wrong-apigroup`:

- a ServiceAccount named `ci-bot`
- a Role named `deploy-reader` intended to grant `get`/`list` on `deployments`
- a RoleBinding named `ci-bot-binding` that correctly binds `deploy-reader` to `ci-bot`
- a real Deployment named `payments-api` (2 replicas, `nginx` image)

A teammate reports that `ci-bot` still cannot read `payments-api`. Confirm this yourself:

```sh
kubectl auth can-i get deployments \
  --as=system:serviceaccount:q106-28-chained-rbac-role-wrong-apigroup:ci-bot \
  -n q106-28-chained-rbac-role-wrong-apigroup
```

It returns `no`, even though the RoleBinding and ServiceAccount names all look correct. Find the
actual bug inside the `deploy-reader` Role's rule and fix it - `deployments` belongs to the `apps`
API group, not the core (empty string) group. Edit the Role in place so its rule for resource
`deployments` uses `apiGroups: ["apps"]`. Do **not** rename or recreate the ServiceAccount or
RoleBinding, and do **not** add any verb beyond `get` and `list` (the fix must not over-grant -
`ci-bot` must still be denied `delete` on `deployments`).

## Hint

Search kubernetes.io/docs for **"Role and ClusterRole"** - the RBAC concept page's rule examples
show which `apiGroups` value each built-in resource actually belongs to, including the difference
between the core group (`""`) and `apps`.
