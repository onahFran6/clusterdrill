# q108-01: Publish a Deployment through a fixed NodePort

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q108-01-nodeport-fixed-port`

`setup.sh` already created a Deployment named `metrics-agent` (image `httpd:2.4-alpine`, 2 replicas,
container port `80`, pod-template label `app=metrics-agent`) in namespace
`q108-01-nodeport-fixed-port`.

Write a Service manifest named `metrics-agent-svc` that:

- is of type `NodePort`
- selects pods with label `app=metrics-agent`
- listens on port `80` and forwards to the container's port `80`
- pins the node port to exactly `30080` (do not let Kubernetes pick one for you)

Apply the manifest so the Service exists in the namespace.

## Hint

Search kubernetes.io/docs for **"NodePort type"** - the Service concept page's NodePort section
shows the `spec.ports[].nodePort` field used to request a specific port instead of an
auto-assigned one.
