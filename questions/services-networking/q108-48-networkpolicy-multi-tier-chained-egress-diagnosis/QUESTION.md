# q108-48: Fix a broken link in a three-tier NetworkPolicy chain

**Domain:** Services and Networking · **Points:** 6 · **Namespace:** `q108-48-networkpolicy-multi-tier-chained-egress-diagnosis`

Three Deployments already exist in namespace
`q108-48-networkpolicy-multi-tier-chained-egress-diagnosis`, each with a `tier` label:

- `frontend` (`tier: frontend`) - must be able to reach `backend`
- `backend` (`tier: backend`) - must be able to reach `database`
- `database` (`tier: database`) - accepts connections only from `backend`

Two egress NetworkPolicies are meant to allow exactly that chain, `frontend` to `backend` to
`database`, and nothing else:

- `frontend-to-backend-egress` selects `tier: frontend` pods and allows egress to `tier: backend`
  pods on TCP port `8080`. This one is correct.
- `backend-to-database-egress` selects `tier: backend` pods and is meant to allow egress to
  `tier: database` pods on TCP port `5432`, but its egress `podSelector` does not match any real
  pod. `backend` has no working egress path to `database`.

Fix `backend-to-database-egress` so its egress rule's `podSelector.matchLabels.tier` is exactly
`database`. Do not change anything else in that policy, and do not touch
`frontend-to-backend-egress`.

## Hint

Search kubernetes.io/docs for **"NetworkPolicy resource"** - the NetworkPolicy concept page shows
that each policy in a multi-hop chain is independent. Compare the destination selector on
`backend-to-database-egress` with the `database` Deployment's `tier` label. A typo in one link
breaks only that link, and the chain still fails end to end until every link is correct.
