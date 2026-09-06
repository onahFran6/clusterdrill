# q101-11: Label existing pods without recreating them

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q101-11-label-pods-selector`

`setup.sh` already created two pods in namespace `q101-11-label-pods-selector`: `batch-a` and
`batch-b`, both with the existing label `role=worker`.

Using imperative `kubectl label` commands (one per pod, or a single command with a selector - your
choice), add the label `env=staging` to both pods **without deleting or recreating either pod**.

## Hint

Search kubernetes.io/docs for **"kubectl label"** - the `kubectl label` command reference shows
how to add labels to existing objects in place, including labeling by selector.
