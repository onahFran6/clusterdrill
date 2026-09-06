# q108-37-fix-nodeport-out-of-range: Fix a Service manifest with an invalid nodePort value

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q108-37-fix-nodeport-out-of-range`

`setup.sh` wrote a Service manifest to
`~/practice-work/q108-37-fix-nodeport-out-of-range/billing-svc.yaml` for a `NodePort` Service
named `billing-svc` (port `80`, target port `80`). It has **not** been applied to the cluster yet -
applying it as written fails validation, because whoever wrote it set `spec.ports[0].nodePort` to
`40090`, outside the valid NodePort range.

Edit the file so it pins the node port to exactly `30090` (a value inside the valid range), then
apply it so the Service exists in the namespace.

## Hint

Search kubernetes.io/docs for **"NodePort type"** - the Service concept page's NodePort section
states the valid node port range is `30000-32767` by default; a value outside that range is
rejected by the API server at admission time.
