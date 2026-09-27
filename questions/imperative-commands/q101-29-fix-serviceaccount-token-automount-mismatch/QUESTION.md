# q101-29: Fix a Pod that cannot list Pods via the API

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q101-29-fix-serviceaccount-token-automount-mismatch`

In namespace `q101-29-fix-serviceaccount-token-automount-mismatch` you'll find a ServiceAccount
named `reader-sa`, a Role named `pod-reader` granting `get`/`list` on Pods, and a RoleBinding
linking `reader-sa` to `pod-reader`. A Pod named `introspector` (image `bitnami/kubectl:latest`)
is supposed to use that identity to query the API server.

Exec into `introspector` and run:

```sh
kubectl auth can-i list pods
```

It fails. Investigate and fix it imperatively:

- Delete and recreate Pod `introspector`, keeping the same name and image
  (`bitnami/kubectl:latest`), running command `sleep 3600`.
- The recreated Pod must run as ServiceAccount `reader-sa`.
- The recreated Pod must not disable token automounting (`automountServiceAccountToken` must be
  left unset or explicitly `true`).

Do not modify the `pod-reader` Role or its RoleBinding. When you're done,
`kubectl exec introspector -- kubectl auth can-i list pods` must print `yes`.

## Hint

Search kubernetes.io/docs for **"configure service account automountServiceAccountToken"** - the
"Configure Service Accounts for Pods" task page covers both `serviceAccountName` and opting a pod
back into (or out of) token automounting.
