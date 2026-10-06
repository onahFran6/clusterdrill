# q114-10: A rollout stuck on its own volume

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q114-10-rollout-stuck-on-its-own-volume`

Deployment `ledger` (1 replica) keeps its database on claim `ledger-db`, which is
`ReadWriteOncePod`. An image upgrade was started, and the new pod has been `Pending` ever since.

- `(ungraded)` Find why the new pod can't start.
- Change `ledger` so this and future upgrades complete, and finish the upgrade to
  `busybox:1.37`.

## Hint

Search kubernetes.io/docs for **"Strategy"** on the Deployments concept page. With 1 replica and
the default strategy, does the controller start the new pod before or after removing the old one?
What does `ReadWriteOncePod` say about two pods holding the same claim at once? Which strategy
type reverses the order?
