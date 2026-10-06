# q116-16: Selecting with expressions

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q116-16-selecting-with-expressions`

Pod `ledger` (label `app: ledger`) must only be reached by pods whose `team` is `payments` or
`billing`, whose `env` is **not** `dev`, and which carry an `audited` label with any value. Test
pods already exist:

- `p1`: `team=payments, env=prod, audited=yes`
- `p2`: `team=billing, env=dev, audited=yes`
- `p3`: `team=billing` (no `env`, no `audited`)
- `p4`: `team=billing, audited=no` (no `env`)

- Create NetworkPolicy `ledger-callers` expressing that rule with `matchExpressions`.
- (ungraded, Task narrative only) Predict, then test, which of `p1`-`p4` can reach `ledger`.

## Hint

Search kubernetes.io/docs for **"NetworkPolicy" "matchExpressions"** - the operators are `In`,
`NotIn`, `Exists`, and `DoesNotExist`, and expressions within one list are ANDed together. Does
`NotIn` match a pod that doesn't have the label at all?
