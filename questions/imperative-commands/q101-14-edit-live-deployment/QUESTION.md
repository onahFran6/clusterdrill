# q101-14: Change a live Deployment's replica count

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q101-14-edit-live-deployment`

A Deployment named `live-edit` (image `nginx:1.25-alpine`, 1 replica) already exists in
namespace `q101-14-edit-live-deployment`.

Change the live Deployment's replica count to `4` against the cluster object directly - do not
reapply a YAML file from disk.

## Hint

Search kubernetes.io/docs for **"kubectl edit"** - the `kubectl edit` command reference explains
how it opens the live object in your editor and applies the diff back to the API server on save.
