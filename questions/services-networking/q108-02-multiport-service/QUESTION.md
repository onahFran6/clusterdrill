# q108-02: Expose two container ports through one multi-port Service

**Domain:** Services and Networking · **Points:** 6 · **Namespace:** `q108-02-multiport-service`

A Deployment named `web-app` (image `httpd:2.4-alpine`, 1 replica,
pod-template label `app=web-app`) already exists. Its single container listens on two ports:
`80` (named `http`) and `8443` (named `https`).

Write a Service manifest named `web-app-svc` of type `ClusterIP` that selects `app=web-app` and
exposes **both** ports at once, using these exact port names on the Service side:

- port name `http`: Service port `80` forwarding to container port `80`
- port name `https`: Service port `443` forwarding to container port `8443`

## Hint

Search kubernetes.io/docs for **"multi-port Services"** - the Service concept page shows that
each port in a multi-port Service must have a `name`. Kubernetes rejects an unnamed port when
there is more than one.
