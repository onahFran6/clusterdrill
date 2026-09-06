# q108-23-expose-deployment-via-kubectl-expose: Expose a bare Deployment as a ClusterIP Service

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q108-23-expose-deployment-via-kubectl-expose`

`setup.sh` already created a Deployment named `billing-worker` (image `httpd:2.4-alpine`, 3
replicas, container port `8443`, pod-template label `app=billing-worker`) in namespace
`q108-23-expose-deployment-via-kubectl-expose`. There is no Service in front of it at all.

Create a Service named exactly `billing-worker-svc` that:

- is of type `ClusterIP`
- selects the Deployment's pods
- listens on port `443` and forwards to the container's port `8443`

so that other pods in the cluster can reach `billing-worker` at `billing-worker-svc:443`.

## Hint

Search kubernetes.io/docs for **"kubectl expose"** - the kubectl reference page shows how to
create a Service from an existing Deployment in one command, including how to set `--name`,
`--port`, and `--target-port`.
