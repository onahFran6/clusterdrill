# q108-42-service-externaltrafficpolicy-local: Preserve client source IP on a NodePort Service

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q108-42-service-externaltrafficpolicy-local`

`setup.sh` already created a Deployment named `edge-gateway` (2 replicas, pod-template label
`app=edge-gateway`) and a `NodePort` Service named `edge-gateway-svc` in namespace
`q108-42-service-externaltrafficpolicy-local`. Right now the Service uses the default traffic
policy, which routes an external request to any node's kube-proxy and then, if needed, hops to a
different node to reach a backend pod - masking the real client IP behind the last hop's source
address by the time it reaches the container.

The application team needs to log real client IPs. Fix the Service so external traffic is only
ever forwarded to a pod running on the node that received the request (no extra hop, source IP
preserved), without changing anything else about the Service.

## Hint

Search kubernetes.io/docs for **"externalTrafficPolicy"** - the Service concept page's
"Preserving the client source IP" section shows `spec.externalTrafficPolicy: Local` as the field
that restricts a Service to only forwarding to pods on the same node the request arrived on.
