# q106-29-secret-env-key-typo-crashloop: Diagnose a CrashLoopBackOff caused by referencing a nonexistent Secret key

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-29-secret-env-key-typo-crashloop`

Namespace `q106-29-secret-env-key-typo-crashloop` already has a Secret named `db-creds` with keys
`username` and `password`, and a Pod named `billing-worker` (image `busybox:1.36`) that should
receive environment variable `DB_PASS` from that Secret. The Pod is not `Running`.

Fix it so that:

- Secret `db-creds` still exists with keys `username` and `password` unchanged.
- Pod `billing-worker` reaches the `Running` phase.
- Inside the running container, `DB_PASS` equals the value stored in `db-creds`'s `password` key.

You may patch the existing Pod or delete and recreate it, as long as the final Pod is still
named `billing-worker` in this namespace.

## Hint

Search kubernetes.io/docs for **"CreateContainerConfigError"** and separately for **"define
container environment variables using secret data"**. Start with `kubectl describe pod` and its
Events. Compare the key the container's `secretKeyRef` requests with the keys that actually
exist on `db-creds`.
