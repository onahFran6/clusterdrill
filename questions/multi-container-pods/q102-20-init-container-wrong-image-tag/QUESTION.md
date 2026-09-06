# q102-20-init-container-wrong-image-tag: Init container fails due to nonexistent image tag

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q102-20-init-container-wrong-image-tag`

A Pod named `report-gen` already exists in this namespace with an init
container named `fetch-config` and a main container named `report-app`.
The init container references image `busybox:99.99`, a tag that does not
exist, so it sits in `ImagePullBackOff`/`ErrImagePull` and never completes -
which means the main container `report-app` never starts.

Fix the Pod so that `fetch-config` uses a valid `busybox` image tag (e.g.
`busybox:1.36`), runs to completion successfully, and lets `report-app`
reach `Running`. You cannot change a Pod's `initContainers[].image` in
place with a JSON merge patch that only touches that field the way you can
for a running container's image via `kubectl set image` - decide whether an
in-place image patch is enough here or whether the Pod must be deleted and
recreated with the corrected image, then do it, keeping the container names
(`fetch-config`, `report-app`) unchanged.

## Hint

Search kubernetes.io/docs for **"init containers"** - the Workloads / Pods
page's "Init Containers" section explains how init containers must exit
successfully before app containers start, and how Pod field immutability
affects fixing a broken init container image.
