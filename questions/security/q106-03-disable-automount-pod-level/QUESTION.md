# q106-03: Stop a pod from automounting its API token

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-03-disable-automount-pod-level`

A pod named `static-renderer` (image `nginx:1.25-alpine`) already exists in namespace
`q106-03-disable-automount-pod-level`. It never talks to the Kubernetes API, so it should not
receive a ServiceAccount token.

Edit the pod so it no longer automounts a ServiceAccount API token. Keep the name
`static-renderer`.

## Hint

Search kubernetes.io/docs for **"automountServiceAccountToken"** - the ServiceAccount concept
page shows this field at both the pod spec and ServiceAccount level. Set it on the pod spec
for this pod only.
