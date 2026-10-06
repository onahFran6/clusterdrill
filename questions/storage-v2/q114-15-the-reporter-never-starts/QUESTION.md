# q114-15: The reporter never starts

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q114-15-the-reporter-never-starts`

Deployment `reporter`'s pod has had a `Pending` status for a day. Its storage should come from
the cluster's default StorageClass.

- `(ungraded)` Find both faults, and where each one shows up.
- Fix things so `reporter` Runs with a 100Mi claim from the cluster's **default** StorageClass.
  The claim must stay named `reports`.

## Hint

Search kubernetes.io/docs for **"Debug Pods"** and the Persistent Volumes concept page's "Class"
section. Read the Pod's events first, then the claim's events - one fault is in the Deployment,
one is in the claim. Which of the two can be edited in place?
