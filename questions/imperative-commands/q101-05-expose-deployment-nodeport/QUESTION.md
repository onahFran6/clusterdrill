# q101-05: Expose a Deployment as a NodePort Service

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q101-05-expose-deployment-nodeport`

`setup.sh` already created a Deployment named `frontend` (image `httpd:2.4-alpine`, 2 replicas,
container port `80`, pod-template label `app=frontend`) in namespace
`q101-05-expose-deployment-nodeport`.

Using a single imperative `kubectl` command, expose this Deployment as a Service named
`frontend-np` that:

- is of type `NodePort`
- listens on port `8080`
- forwards to the container's port `80`

## Hint

Search kubernetes.io/docs for **"kubectl expose deployment NodePort"** - the `kubectl expose`
reference covers exposing a Deployment and picking a Service `--type`.
