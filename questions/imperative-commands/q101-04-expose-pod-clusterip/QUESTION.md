# q101-04: Expose an existing pod as a ClusterIP Service

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q101-04-expose-pod-clusterip`

`setup.sh` already created a running pod named `catalog` (image `nginx:1.25-alpine`, listening on
container port `80`) in namespace `q101-04-expose-pod-clusterip`, labeled `app=catalog`.

Using a single imperative `kubectl` command, expose this pod as a Service named `catalog-svc`
that:

- is of type `ClusterIP`
- listens on port `80`
- forwards to the pod's container port `80`

## Hint

Search kubernetes.io/docs for **"kubectl expose pod"** - the `kubectl expose` command reference
shows how to create a Service from an existing pod without writing a Service manifest by hand.
