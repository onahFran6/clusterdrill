# q101-23-diagnose-wrong-configmap-key-reference: Diagnose and fix a pod stuck in CreateContainerConfigError from a bad envFrom key

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q101-23-diagnose-wrong-configmap-key-reference`

`setup.sh` already created a ConfigMap named `app-settings` (keys `LOG_LEVEL=info` and
`MAX_CONNECTIONS=100`) and a Pod named `settings-reader` with a single container also named
`settings-reader`, image `nginx:1.25-alpine`.

The pod is not starting. Diagnose why using `kubectl describe pod/settings-reader` and/or
`kubectl get events`, then fix it imperatively (delete and recreate the pod - for example with
`kubectl run ... --dry-run=client -o yaml` piped through an edit, or `kubectl replace --force -f -`)
so that:

- The pod is named `settings-reader`, its container is named `settings-reader`, running the same
  image, in namespace `q101-23-diagnose-wrong-configmap-key-reference`.
- The container still loads every key from ConfigMap `app-settings` via `envFrom`.
- The container still has one extra, explicitly named environment variable that sources its value
  from ConfigMap `app-settings` via `valueFrom.configMapKeyRef` (do not replace it with a hardcoded
  literal value) - just pointed at the correct key so the container actually starts.
- The pod reaches `Running` and `Ready`, and a shell into the container shows the fixed environment
  variable resolving to the correct value.

## Hint

Search kubernetes.io/docs for **"define container environment variable using configmap data"** -
the Configure a Pod to Use a ConfigMap task page shows both the `envFrom` and single-key
`valueFrom.configMapKeyRef` forms, plus how a typo'd key surfaces as `CreateContainerConfigError`
in `kubectl describe pod`.
