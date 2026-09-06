# q106-03: Stop a pod from automounting its API token

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-03-disable-automount-pod-level`

A security review flagged that pod `static-renderer` (already created by `setup.sh` in namespace
`q106-03-disable-automount-pod-level`, image `nginx:1.25-alpine`) never talks to the Kubernetes
API, so it should not be handed a ServiceAccount token at all.

Edit the pod so it no longer automounts a ServiceAccount API token, without deleting and
recreating it under a different name.

## Hint

Search kubernetes.io/docs for **"automountServiceAccountToken"** - the ServiceAccount concept
page shows this field at both the pod spec and ServiceAccount level.
