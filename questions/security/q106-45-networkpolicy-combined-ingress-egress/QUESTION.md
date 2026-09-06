# q106-45: Lock down both ingress and egress for a Pod in one NetworkPolicy

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-45-networkpolicy-combined-ingress-egress`

Two Pods already exist: `payments-api` (labeled `app: payments-api`, port 80) and `ledger-db`
(labeled `app: ledger-db`, port 5432). Create a single NetworkPolicy named `payments-api-policy`
that selects `app: payments-api` and enforces, in one policy:

- **Ingress:** allow only TCP port 80 from pods labeled `app: api-gateway`.
- **Egress:** allow only TCP port 5432 to pods labeled `app: ledger-db`, plus UDP port 53 for DNS.

Everything else, in both directions, must remain blocked.

## Hint

Search kubernetes.io/docs for **"behavior of to and from selectors"** - the NetworkPolicy concept
page shows a single policy object with both `policyTypes: [Ingress, Egress]` and separate
`ingress`/`egress` rule lists.
