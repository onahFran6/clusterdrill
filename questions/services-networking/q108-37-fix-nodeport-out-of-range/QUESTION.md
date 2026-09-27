# q108-37: Fix a Service manifest with an invalid nodePort value

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q108-37-fix-nodeport-out-of-range`

A Service manifest at
`~/practice-work/q108-37-fix-nodeport-out-of-range/billing-svc.yaml` describes a `NodePort`
Service named `billing-svc` (port `80`, target port `80`). It has not been applied yet.
Applying it as written fails validation because `spec.ports[0].nodePort` is outside the valid
NodePort range.

Edit the file so it pins the node port to exactly `30090`, then apply it so the Service exists
in the namespace.

## Hint

Search kubernetes.io/docs for **"NodePort type"** - the Service concept page's NodePort section
states the valid node port range is `30000-32767` by default. A value outside that range is
rejected by the API server at admission time.
