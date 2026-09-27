# q101-23: Fix a Pod stuck in CreateContainerConfigError

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q101-23-diagnose-wrong-configmap-key-reference`

In namespace `q101-23-diagnose-wrong-configmap-key-reference` you'll find a ConfigMap named
`app-settings` (keys `LOG_LEVEL=info` and `MAX_CONNECTIONS=100`) and a Pod named
`settings-reader` (container also named `settings-reader`, image `nginx:1.25-alpine`). The Pod is
not starting.

Investigate with `kubectl describe pod/settings-reader` and/or `kubectl get events`, then fix it
imperatively (delete and recreate is fine) so that:

- The Pod is named `settings-reader`, its container is named `settings-reader`, running the same
  image, in this namespace.
- The container still loads every key from ConfigMap `app-settings` via `envFrom`.
- The container still has one extra, explicitly named environment variable sourced from
  ConfigMap `app-settings` via `valueFrom.configMapKeyRef` (not a hardcoded literal) - pointed at
  a key that actually exists, so the container starts.
- The Pod reaches `Running` and `Ready`, and a shell into the container shows that extra
  environment variable resolving to the correct value.

## Hint

Search kubernetes.io/docs for **"define container environment variable using configmap data"** -
the Configure a Pod to Use a ConfigMap task page shows both the `envFrom` and single-key
`valueFrom.configMapKeyRef` forms, plus how a typo'd key surfaces as `CreateContainerConfigError`
in `kubectl describe pod`.
