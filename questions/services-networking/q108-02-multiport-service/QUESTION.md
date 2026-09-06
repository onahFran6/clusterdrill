# q108-02: Expose two container ports through one multi-port Service

**Domain:** Services and Networking · **Points:** 6 · **Namespace:** `q108-02-multiport-service`

`setup.sh` already created a Deployment named `web-app` (image `httpd:2.4-alpine`, 1 replica,
pod-template label `app=web-app`) whose single container listens on two container ports: `80`
(named `http`) and `8443` (named `https`).

Write a Service manifest named `web-app-svc` of type `ClusterIP` that selects `app=web-app` and
exposes **both** ports at once, using these exact port names on the Service side:

- port name `http`: Service port `80` forwarding to container port `80`
- port name `https`: Service port `443` forwarding to container port `8443`

Every port entry in a multi-port Service must be named - Kubernetes rejects an unnamed port
when there is more than one.

## Hint

Search kubernetes.io/docs for **"multi-port Services"** - the Service concept page shows the
requirement that each port in a multi-port Service definition must have a `name`.
