# q104-24: Add a pod label without changing the selector

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-24-immutable-selector-rejected`

A Deployment named `notify-service` already exists in namespace
`q104-24-immutable-selector-rejected` (image `busybox:1.36`, 2 replicas) with
`spec.selector.matchLabels: {app: notify-service}` and the matching pod template label
`app: notify-service`.

A teammate tried to add `tier: backend` by patching `spec.selector.matchLabels` directly; the
API server rejected the edit. Their rejected attempt is saved at
`~/practice-work/q104-24-immutable-selector-rejected/attempted-selector-patch.yaml` in your
terminal's working directory - do not repeat that approach.

Add `tier: backend` to the Deployment's pod template labels only
(`spec.template.metadata.labels`), leaving `spec.selector.matchLabels` exactly
`{app: notify-service}`. Confirm the Deployment reconciles with 2 Ready replicas whose pods
carry both `app=notify-service` and `tier=backend`.

## Hint

Search kubernetes.io/docs for **"deployment spec selector immutable"** - the Deployment concept
page's "Selector" section explains that `.spec.selector` cannot be changed after creation, and
that pod template labels must be a superset of the selector, so extra labels can be added on
the template instead.
