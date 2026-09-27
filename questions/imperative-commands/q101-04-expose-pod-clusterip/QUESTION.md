# q101-04: Expose a Pod as a ClusterIP Service

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q101-04-expose-pod-clusterip`

A running Pod named `catalog` (image `nginx:1.25-alpine`, container port `80`, label
`app=catalog`) already exists in namespace `q101-04-expose-pod-clusterip`.

Using a single imperative `kubectl` command, expose this Pod as a Service named `catalog-svc`
that:

- is of type `ClusterIP`
- listens on port `80`
- forwards to the Pod's container port `80`

## Hint

Search kubernetes.io/docs for **"kubectl expose pod"** - the `kubectl expose` command reference
shows how to create a Service from an existing pod without writing a Service manifest by hand.
