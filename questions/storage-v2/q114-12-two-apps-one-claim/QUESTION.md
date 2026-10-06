# q114-12: Two apps, one claim, separate folders

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q114-12-two-apps-one-claim`

A single claim `shared` already exists. Two Deployments, `api` and `worker`, must not see each
other's files on it.

- Mount `shared` into Deployment `api` (1 replica, `busybox:1.36`) so it only sees its own `api/`
  folder at `/data` - use `subPath`. Do the same for Deployment `worker`, using `worker/`.
- Each Deployment's container writes `/data/owner` containing its own name (`api` or `worker`)
  once, then sleeps.

## Hint

Search kubernetes.io/docs for **"subPath"** on the Volumes concept page. One `volumeMounts` field
mounts a sub-folder of a volume instead of its root - does the folder have to exist beforehand?
This works because both Deployments land on the one node this cluster has; sharing a claim across
multiple nodes needs a `ReadWriteMany`-capable class, which `shared` isn't.
