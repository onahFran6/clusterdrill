# q105-15: Lock a Secret's data against further changes

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q105-15-immutable-secret`

`setup.sh` already created a generic Secret named `signing-key` with a key `KEY_ID=key-2026-a`,
in namespace `q105-15-immutable-secret`. It is currently mutable.

Update `signing-key` so that it is marked **immutable** - once you make this change, Kubernetes
will reject any further attempt to change its `data`. Keep the existing `KEY_ID=key-2026-a` value
exactly as it is; only the immutability flag should change.

## Hint

Search kubernetes.io/docs for **"immutable Secrets"** - the Secrets concept page documents the
same `immutable` field used by ConfigMaps, and why locking rarely-changing credentials this way
also reduces load on the API server (kube-apiserver stops watching an immutable object for
changes).
