# q113-17: One dash too many

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q113-17-and-vs-or-selector-semantics`

Team Lyra's `api` pods should accept ingress only from pods labeled `role=scraper` running in
namespaces labeled `team=monitoring` - both conditions together. A teammate wrote NetworkPolicy
`allow-scrapers` to express that, but a security scan found far more traffic getting through than
intended.

- Fix `allow-scrapers` so a single `from` entry requires **both** `namespaceSelector: {team:
  monitoring}` **and** `podSelector: {role: scraper}` together (AND, not OR).
- (ungraded, Task narrative only) Count the list items under the broken policy's `from` field -
  separate list items combine with OR, while selectors inside one item combine with AND.

This cluster's default CNI does not enforce NetworkPolicy, so grading checks the policy
object's fields only, not live traffic blocking.

## Hint

Search kubernetes.io/docs for **"NetworkPolicy" "NetworkPolicyPeer"** - the NetworkPolicy API
reference states that a single `from`/`to` entry may combine `namespaceSelector` and
`podSelector` (AND), but two separate list entries are evaluated independently and ORed together.
