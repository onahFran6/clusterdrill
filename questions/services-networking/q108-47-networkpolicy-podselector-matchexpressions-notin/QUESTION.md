# q108-47-networkpolicy-podselector-matchexpressions-notin: Exclude a tier by label operator, not by value

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q108-47-networkpolicy-podselector-matchexpressions-notin`

`setup.sh` already created a Deployment named `worker-pool` (pod-template labels `app: worker-pool`
plus `tier: current`) and a second Deployment `worker-pool-legacy` (pod-template labels
`app: worker-pool`, `tier: legacy`) in namespace
`q108-47-networkpolicy-podselector-matchexpressions-notin` - both are still mid-migration and
share the same `app` label. It also created a NetworkPolicy named `worker-pool-restrict-egress`
selecting `app: worker-pool` pods, but its egress rule's `podSelector` (which is meant to allow
egress only to pods that are **not** on the `legacy` tier, of which there may eventually be many
different non-legacy tier values) currently uses `matchLabels: {tier: current}` - an exact-value
match that only works for today's one non-legacy tier name and will silently stop working the
moment a new non-legacy tier value shows up.

Rewrite that `podSelector` to use `matchExpressions` instead of `matchLabels`, with a single
expression that allows any pod whose `tier` label is **not** `legacy` (`key: tier`,
`operator: NotIn`, `values: [legacy]`) - this correctly allows `tier: current` today and any
future non-legacy tier value, without ever needing to be updated again. Leave everything else
about the policy (its own `podSelector`, `policyTypes`, ports) unchanged.

## Hint

Search kubernetes.io/docs for **"matchExpressions"** - the Labels and Selectors concept page's
"Resources that support set-based requirements" section shows `matchExpressions` entries using
`In`/`NotIn`/`Exists`/`DoesNotExist` operators as a more expressive alternative to
`matchLabels`'s exact-value-only matching; `NetworkPolicy` `podSelector` fields accept either.
