# q108-47: Exclude a tier by label operator, not by value

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q108-47-networkpolicy-podselector-matchexpressions-notin`

A Deployment named `worker-pool` (pod-template labels `app: worker-pool`
and `tier: current`) and a Deployment `worker-pool-legacy` (pod-template labels
`app: worker-pool`, `tier: legacy`) already exist in namespace
`q108-47-networkpolicy-podselector-matchexpressions-notin`. Both share the `app` label. A
NetworkPolicy named `worker-pool-restrict-egress` selects `app: worker-pool` pods. Its egress
rule's `podSelector` currently uses `matchLabels` with `tier: current`, which only matches that
one value.

Rewrite that `podSelector` to use `matchExpressions` instead of `matchLabels`, with a single
expression that allows any pod whose `tier` label is **not** `legacy` (`key: tier`,
`operator: NotIn`, `values: [legacy]`). Leave everything else about the policy (its own
`podSelector`, `policyTypes`, ports) unchanged.

## Hint

Search kubernetes.io/docs for **"matchExpressions"** - the Labels and Selectors concept page's
"Resources that support set-based requirements" section shows `matchExpressions` entries using
`In`/`NotIn`/`Exists`/`DoesNotExist`. `matchLabels` only matches one exact value, so a new
non-legacy `tier` would silently stop matching it. A NetworkPolicy `podSelector` accepts either
form.
