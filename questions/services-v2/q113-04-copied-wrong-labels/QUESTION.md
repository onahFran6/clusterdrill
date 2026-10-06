# q113-04: Copied the wrong labels

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q113-04-copied-wrong-labels`

Team Altair wrote Service `ledger-svc` by copying labels from Deployment `ledger`'s own YAML.
Clients get errors, even though all 3 `ledger` pods are Running.

- Fix `ledger-svc` only (do not touch the Deployment) so requests to `ledger-svc:80` return the
  nginx page.
- (ungraded, Task narrative only) Be ready to explain both causes: which Deployment YAML field
  actually ends up on the pods, and why the copied selector missed it.

## Hint

Search kubernetes.io/docs for **"Service" "the service selector"** - the Service concept page
states a Service matches pods by their own labels, which come from
`spec.template.metadata.labels`, never a Deployment's own top-level `metadata.labels`. Compare
`kubectl get pods --show-labels` with the Service's current selector, then check what the pods
actually listen on.
