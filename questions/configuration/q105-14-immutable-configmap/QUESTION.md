# q105-14: Lock a ConfigMap's data against further changes

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q105-14-immutable-configmap`

`setup.sh` already created a ConfigMap named `release-info` with a key `VERSION=3.1.0`, in
namespace `q105-14-immutable-configmap`. It is currently mutable.

Update `release-info` so that it is marked **immutable** - once you make this change, Kubernetes
will reject any further attempt to change its `data`. Keep the existing `VERSION=3.1.0` key
exactly as it is; only the immutability flag should change.

## Hint

Search kubernetes.io/docs for **"immutable ConfigMaps"** - the ConfigMaps concept page explains
the `immutable` field, why it protects against accidental updates, and that an immutable
ConfigMap must be deleted and recreated (not edited) to change its data afterward.
