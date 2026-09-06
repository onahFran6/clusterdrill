# q108-22-add-second-service-port-mapping: Add a missing port mapping to an existing single-port Service

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q108-22-add-second-service-port-mapping`

`setup.sh` already created a Deployment named `metrics-agent` (1 replica, container port-template
label `app=metrics-agent`) whose single container listens on two container ports: `8080` (the
application, already exposed through the Service) and `9090` (a `/metrics` endpoint that scrapers
need to reach). The accompanying Service `metrics-agent-svc` only maps one port, so `9090` is not
reachable through the Service at all.

Edit the Service `metrics-agent-svc` to add a second named port mapping, without removing or
renaming the existing one:

- keep the existing port name `http`: Service port `8080` forwarding to container port `8080`
- add a new port name `metrics`: Service port `9090` forwarding to container port `9090`

Every port entry in a multi-port Service must be named, so `metrics-agent-svc` must end up with
exactly two named ports.

## Hint

Search kubernetes.io/docs for **"multi-port Services"** - the Service concept page shows the
requirement that each port in a multi-port Service definition must have a `name`, and that you can
edit a Service's `spec.ports` list in place with `kubectl edit` or `kubectl apply`.
