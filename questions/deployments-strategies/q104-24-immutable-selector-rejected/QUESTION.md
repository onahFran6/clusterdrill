# q104-24-immutable-selector-rejected: Fix a rejected Deployment edit caused by changing the selector

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-24-immutable-selector-rejected`

`setup.sh` already created a Deployment named `notify-service` (image `busybox:1.36`, 2 replicas)
in namespace `q104-24-immutable-selector-rejected`, with `spec.selector.matchLabels: {app: notify-service}`
and the matching pod template label `app: notify-service`.

Someone on the team tried to add a `tier: backend` label by patching `spec.selector.matchLabels`
directly, and the API server rejected it because `spec.selector` is immutable once a Deployment
exists. Their rejected attempt is saved for reference at `~/practice-work/q104-24-immutable-selector-rejected/attempted-selector-patch.yaml`
in your terminal's working directory - do not repeat that mistake.

Achieve the equivalent relabeling goal without touching the selector: add the label `tier: backend`
to the Deployment's **pod template** only (`spec.template.metadata.labels`), leaving
`spec.selector.matchLabels` exactly as `{app: notify-service}` (no new keys added there either).
Confirm the Deployment reconciles with 2 Ready replicas whose pods carry both `app=notify-service`
and `tier=backend` labels.

## Hint

Search kubernetes.io/docs for **"deployment spec selector immutable"** - the Deployment concept
page's "Selector" section explains that `.spec.selector` cannot be changed after creation, and
that pod template labels must be a superset of the selector, not an exact match, so extra labels
can always be added there instead.
