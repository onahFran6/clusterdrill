# q101-14: Edit a live Deployment's replica count

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q101-14-edit-live-deployment`

`setup.sh` already created a Deployment named `live-edit` (image `nginx:1.25-alpine`, 1 replica)
in namespace `q101-14-edit-live-deployment`.

Using `kubectl edit` (or `kubectl patch`, which is what `kubectl edit` does under the hood when
you save a changed manifest), change the live Deployment's `spec.replicas` to `4` directly against
the cluster object - don't reapply a YAML file from disk.

## Hint

Search kubernetes.io/docs for **"kubectl edit"** - the `kubectl edit` command reference explains
how it opens the live object in your editor and applies the diff back to the API server on save.
