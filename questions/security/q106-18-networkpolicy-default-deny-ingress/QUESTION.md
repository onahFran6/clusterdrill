# q106-18: Lock a namespace down with a default-deny NetworkPolicy

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-18-networkpolicy-default-deny-ingress`

Every pod in namespace `q106-18-networkpolicy-default-deny-ingress` currently accepts inbound
traffic from anywhere in the cluster, which a security review flagged as the wrong default.

Create a NetworkPolicy named `default-deny-ingress` in this namespace that denies all ingress
traffic to every pod in the namespace, unless a more specific NetworkPolicy is added later to
allow something explicitly.

## Hint

Search kubernetes.io/docs for **"default deny all ingress traffic"** - the NetworkPolicy concept
page has a copy-paste example under exactly that heading, using an empty `podSelector` to select
every pod in the namespace.
