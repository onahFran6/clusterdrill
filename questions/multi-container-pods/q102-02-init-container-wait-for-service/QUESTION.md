# q102-02: Init container waits for a dependency Service

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q102-02-init-container-wait-for-service`

A ClusterIP Service named `user-db` already exists in this namespace (it has no
backing Pods yet, but its DNS name is resolvable as soon as the Service object
exists).

Create a Pod named `app` with:

- An init container named `wait-for-db` (image `busybox:1.36`) that blocks
  startup of the main container until the `user-db` Service's DNS name can be
  resolved. Use a loop such as
  `until nslookup user-db; do sleep 2; done` as its command.
- A main container named `main` (image `nginx:1.27-alpine`).

The main container must not start until the init container's DNS check
succeeds - this is the classic "wait for a dependency" init container
pattern.

## Hint

Search kubernetes.io/docs for **"init containers"** - the Workloads page's
"Init Containers" section shows the pattern of using an init container to
wait on another Service before the app container starts.
