# q101-29-fix-serviceaccount-token-automount-mismatch: Fix a pod that can't reach the API server because of a ServiceAccount/RBAC and automount mismatch

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q101-29-fix-serviceaccount-token-automount-mismatch`

`setup.sh` already created a ServiceAccount named `reader-sa`, a Role named `pod-reader` granting
`get`/`list` on `pods`, and a RoleBinding that correctly links `reader-sa` to `pod-reader` - all in
namespace `q101-29-fix-serviceaccount-token-automount-mismatch`. It also created a pod named
`introspector` (image `bitnami/kubectl:latest`) that is supposed to use that identity to query the
API server, but whoever wrote its manifest got it wrong.

Exec into `introspector` and run:

```sh
kubectl auth can-i list pods
```

It fails. Diagnose why (check which ServiceAccount the pod actually runs as, and whether it even
has a mounted token under `/var/run/secrets/kubernetes.io/serviceaccount/`), then fix it
imperatively:

- Delete and recreate the pod `introspector`, keeping the same name and the same image
  (`bitnami/kubectl:latest`), running command `sleep 3600`.
- The recreated pod must run as ServiceAccount `reader-sa`.
- The recreated pod must not disable token automounting (`automountServiceAccountToken` must be
  left unset or explicitly `true`).

Do not modify the `pod-reader` Role or its RoleBinding - they are already correct. When you're
done, `kubectl exec`-ing into `introspector` and running `kubectl auth can-i list pods` must print
`yes`.

## Hint

Search kubernetes.io/docs for **"configure service account automountServiceAccountToken"** - the
"Configure Service Accounts for Pods" task page covers both `serviceAccountName` and opting a pod
back into (or out of) token automounting.
