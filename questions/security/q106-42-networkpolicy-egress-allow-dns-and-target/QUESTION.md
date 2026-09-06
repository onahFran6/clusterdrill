# q106-42: Restrict egress to DNS and one target, without breaking name resolution

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-42-networkpolicy-egress-allow-dns-and-target`

Two Pods already exist in this namespace: `report-generator` (labeled `app: report-generator`)
and `data-store` (labeled `app: data-store`, listening on port 80). Create a NetworkPolicy named
`report-generator-egress` that selects `app: report-generator` and restricts its egress traffic to
exactly two things:

- DNS lookups (UDP port 53)
- TCP port 80 to pods labeled `app: data-store`

All other egress must remain blocked.

## Hint

Search kubernetes.io/docs for **"the NetworkPolicy resource"** - the concept page's egress example
shows a policy with multiple `egress` rule entries, and warns that restricting egress without also
allowing DNS (port 53) breaks name resolution for the selected pods.
