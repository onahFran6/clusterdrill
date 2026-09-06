# q106-38: Allow ingress to a Pod only from a specific pod selector

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-38-networkpolicy-allow-podselector`

A Pod named `billing-db` (labeled `app: billing-db`) already exists in this namespace. Create a
NetworkPolicy named `billing-db-allow` that selects `app: billing-db` and permits ingress traffic
**only** from pods labeled `app: billing-worker` - all other ingress must remain blocked.

## Hint

Search kubernetes.io/docs for **"NetworkPolicy resource"** - the concept page's example shows an
ingress rule's `from` list using a `podSelector` to allow traffic only from pods matching specific
labels within the same namespace.
