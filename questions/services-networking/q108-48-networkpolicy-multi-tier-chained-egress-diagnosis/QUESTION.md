# q108-48-networkpolicy-multi-tier-chained-egress-diagnosis: Fix a broken link in a three-tier NetworkPolicy chain

**Domain:** Services and Networking · **Points:** 6 · **Namespace:** `q108-48-networkpolicy-multi-tier-chained-egress-diagnosis`

`setup.sh` already created three Deployments in namespace
`q108-48-networkpolicy-multi-tier-chained-egress-diagnosis`, each with a `tier` label:

- `frontend` (`tier: frontend`) - must be able to reach `backend`
- `backend` (`tier: backend`) - must be able to reach `database`
- `database` (`tier: database`) - accepts connections only from `backend`

It also created two egress NetworkPolicies meant to allow exactly that chain,
`frontend -> backend -> database`, and nothing else:

- `frontend-to-backend-egress` - selects `tier: frontend` pods, allows egress to `tier: backend`
  pods on TCP port `8080`. This one is correct.
- `backend-to-database-egress` - selects `tier: backend` pods, meant to allow egress to
  `tier: database` pods on TCP port `5432`, but its egress rule's `podSelector` was typed as
  `tier: databse` (missing the middle `a`), so it never matches any real pod. `backend` currently
  has no working egress path to `database` at all.

Fix `backend-to-database-egress` so its egress rule's `podSelector.matchLabels.tier` is exactly
`database`, without changing anything else in that policy and without touching
`frontend-to-backend-egress` (it is already correct).

## Hint

Search kubernetes.io/docs for **"NetworkPolicy resource"** - the NetworkPolicy concept page shows
that each policy in a multi-hop chain like this is independent: a typo in one link's selector
breaks only that link, not the others, but the chain as a whole still fails end-to-end until every
link is correct.
