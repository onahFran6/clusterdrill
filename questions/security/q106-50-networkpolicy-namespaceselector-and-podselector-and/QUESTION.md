# q106-50: Combine a namespace selector and a pod selector as a logical AND

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-50-networkpolicy-namespaceselector-and-podselector-and`

This namespace is already labeled `team: platform`. A Pod named `secrets-vault` (labeled
`app: secrets-vault`, port 80) already exists. Create a NetworkPolicy named `secrets-vault-allow`
that selects `app: secrets-vault` and permits ingress **only** from pods that satisfy both of these
at once: they run in a namespace labeled `team: platform`, **and** they themselves are labeled
`role: trusted-caller`. A pod that matches only one of the two must still be blocked.

## Hint

Search kubernetes.io/docs for **"behavior of to and from selectors"** - the NetworkPolicy concept
page explains that a `namespaceSelector` and a `podSelector` listed together **inside the same**
`from` entry are ANDed (must both match), while listing them as **separate** entries in the `from`
list ORs them instead.
