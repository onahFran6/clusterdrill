# q106-28-chained-rbac-role-wrong-apigroup: Fix a Role that grants access to the wrong apiGroup for a Deployment-reading permission

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-28-chained-rbac-role-wrong-apigroup`

Namespace `q106-28-chained-rbac-role-wrong-apigroup` already has:

- a ServiceAccount named `ci-bot`
- a Role named `deploy-reader`, intended to grant `get` and `list` on `deployments`
- a RoleBinding named `ci-bot-binding` that binds `deploy-reader` to `ci-bot`
- a Deployment named `payments-api` (2 replicas, image `nginx`)

`ci-bot` still cannot read `payments-api`. Update Role `deploy-reader` in place so `ci-bot` can
`get` and `list` Deployments in this namespace. `ci-bot` must remain unable to `delete`
Deployments. Do not rename or recreate the ServiceAccount or the RoleBinding, and do not add
any verb beyond `get` and `list`.

## Hint

Search kubernetes.io/docs for **"Role and ClusterRole"** - the RBAC concept page's rule examples
show which `apiGroups` value each built-in resource belongs to, including the difference between
the core group (`""`) and `apps`. `deployments` is an `apps` resource.

Confirm the denial before the fix:

```sh
kubectl auth can-i get deployments \
  --as=system:serviceaccount:q106-28-chained-rbac-role-wrong-apigroup:ci-bot \
  -n q106-28-chained-rbac-role-wrong-apigroup
```

That returns `no` until the Role's rule for `deployments` uses `apiGroups: ["apps"]`.
