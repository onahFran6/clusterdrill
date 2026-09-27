# q108-42: Preserve client source IP on a NodePort Service

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q108-42-service-externaltrafficpolicy-local`

A Deployment named `edge-gateway` (2 replicas, pod-template label
`app=edge-gateway`) and a `NodePort` Service named `edge-gateway-svc` already exist in namespace
`q108-42-service-externaltrafficpolicy-local`. External requests currently lose the original
client address before they reach the container.

Fix the Service so external traffic is only ever forwarded to a pod running on the node that
received the request, and the source IP is preserved. Do not change anything else about the
Service.

## Hint

Search kubernetes.io/docs for **"externalTrafficPolicy"** - the Service concept page's
"Preserving the client source IP" section shows `spec.externalTrafficPolicy: Local`. The default
policy may send the packet to another node's kube-proxy first, so the container sees the last
hop's address instead of the client.
