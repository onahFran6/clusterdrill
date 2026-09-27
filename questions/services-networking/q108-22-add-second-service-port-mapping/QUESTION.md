# q108-22: Add a missing port mapping to an existing single-port Service

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q108-22-add-second-service-port-mapping`

A Deployment named `metrics-agent` (1 replica, pod-template label
`app=metrics-agent`) already exists. Its single container listens on two ports: `8080` (the
application, already exposed through the Service) and `9090` (a `/metrics` endpoint). The
Service `metrics-agent-svc` only maps one port, so `9090` is not reachable through it.

Edit `metrics-agent-svc` to add a second named port mapping, without removing or renaming the
existing one:

- keep the existing port name `http`: Service port `8080` forwarding to container port `8080`
- add a new port name `metrics`: Service port `9090` forwarding to container port `9090`

The Service must end up with exactly those two named ports.

## Hint

Search kubernetes.io/docs for **"multi-port Services"** - the Service concept page shows that
each port in a multi-port Service must have a `name`, and that you can edit a Service's
`spec.ports` list in place with `kubectl edit` or `kubectl apply`.
