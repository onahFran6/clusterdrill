# q108-07: Pin client sessions to the same pod with session affinity

**Domain:** Services and Networking · **Points:** 6 · **Namespace:** `q108-07-session-affinity-clientip`

`setup.sh` already created a Deployment named `session-store` (image `httpd:2.4-alpine`, 3
replicas, container port `80`, pod-template label `app=session-store`) and a ClusterIP Service
named `session-store-svc` (port `80` -> `80`, selecting `app=session-store`) in namespace
`q108-07-session-affinity-clientip`. Right now the Service load-balances every request across all
three pods round-robin, which breaks an in-memory session cache that assumes a client always
lands on the same pod.

Update the existing Service `session-store-svc` so that repeated requests from the same client IP
are always routed to the same backend pod for up to one hour (`3600` seconds) of inactivity,
without changing its selector, ports, or type.

## Hint

Search kubernetes.io/docs for **"session affinity"** - the Service concept page's Session
affinity section shows the `spec.sessionAffinity: ClientIP` field and the
`spec.sessionAffinityConfig.clientIP.timeoutSeconds` field used to control the affinity window.
