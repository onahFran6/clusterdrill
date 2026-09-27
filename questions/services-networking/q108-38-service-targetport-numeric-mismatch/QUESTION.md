# q108-38: Fix a Service forwarding to the wrong container port

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q108-38-service-targetport-numeric-mismatch`

A Deployment named `media-worker` (image `httpd:2.4-alpine`,
pod-template label `app=media-worker`, `containerPort: 8080`) and a Service named
`media-worker-svc` already exist in namespace
`q108-38-service-targetport-numeric-mismatch`. The Service selects the Deployment's pods and has
endpoints, but traffic is forwarded to the wrong container port.

Fix the Service's `spec.ports[0].targetPort` to `8080` so it matches the container's real port. Do
not change the Service's `port` (the external-facing port, `80`) and do not change the Deployment.

## Hint

Search kubernetes.io/docs for **"Service" "targetPort"** - the Service concept page explains that
`port` is what clients connect to on the Service itself, while `targetPort` is the port on the
backing Pod the traffic is actually forwarded to. The two are independent, and the API does not
check that `targetPort` matches a declared `containerPort`. Compare the current `targetPort` with
`8080`.
