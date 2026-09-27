# q102-20: Unstick an init container stuck on ImagePullBackOff

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q102-20-init-container-wrong-image-tag`

A Pod named `report-gen` already exists in this namespace with an init
container named `fetch-config` and a main container named `report-app`.
`fetch-config` sits in `ImagePullBackOff` / `ErrImagePull` and never
completes, so `report-app` never starts.

Fix the Pod so `fetch-config` uses a valid `busybox` image tag (e.g.
`busybox:1.36`), runs to completion successfully, and lets `report-app`
reach `Running`. Keep the container names (`fetch-config`, `report-app`)
unchanged. Decide whether an in-place image patch is enough for an init
container, or whether the Pod must be deleted and recreated.

## Hint

Search kubernetes.io/docs for **"init containers"** - the Workloads / Pods
page's "Init Containers" section explains how init containers must exit
successfully before app containers start, and how Pod field immutability
affects fixing a broken init container image.
