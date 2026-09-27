# q101-11: Label existing Pods without recreating them

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q101-11-label-pods-selector`

Two Pods named `batch-a` and `batch-b` already exist in namespace
`q101-11-label-pods-selector`, both with the label `role=worker`.

Add the label `env=staging` to both Pods without deleting or recreating either one. Imperative
`kubectl label` is fine (one command per Pod, or a single command with a selector).

## Hint

Search kubernetes.io/docs for **"kubectl label"** - the `kubectl label` command reference shows
how to add labels to existing objects in place, including labeling by selector.
