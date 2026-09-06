# q108-38-service-targetport-numeric-mismatch: Fix a Service forwarding to the wrong container port

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q108-38-service-targetport-numeric-mismatch`

`setup.sh` already created a Deployment named `media-worker` (image `httpd:2.4-alpine`,
pod-template label `app=media-worker`, `containerPort: 8080`) and a Service named
`media-worker-svc` in namespace `q108-38-service-targetport-numeric-mismatch`. The Service
correctly selects the Deployment's pods and has endpoints populated, but its
`spec.ports[0].targetPort` is set to `80`, which does not match the container's declared port,
`8080` - Kubernetes never validates that a Service's `targetPort` matches a real `containerPort`,
so the mismatch was applied without error.

Fix the Service's `spec.ports[0].targetPort` to `8080` so it matches the container's real port. Do
not change the Service's `port` (external-facing port, `80`) and do not change the Deployment.

## Hint

Search kubernetes.io/docs for **"Service" "targetPort"** - the Service concept page's field
reference explains that `port` is what clients connect to on the Service itself, while
`targetPort` is the port on the backing Pod the traffic is actually forwarded to - the two are
independent fields.
