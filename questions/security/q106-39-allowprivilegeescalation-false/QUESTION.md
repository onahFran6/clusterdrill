# q106-39: Lock down a container's privilege escalation

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-39-allowprivilegeescalation-false`

`setup.sh` already created a running Pod named `web-worker` (image `nginx:1.25-alpine`) with no
`securityContext.allowPrivilegeEscalation` set - which defaults to allowing it. Without changing
the image or any other container field, ensure `web-worker`'s container explicitly sets
`allowPrivilegeEscalation: false` and is Running again.

## Hint

Search kubernetes.io/docs for **"set the security context for a container"** - the security
context task page covers the `allowPrivilegeEscalation` field and notes it can only be set at
container creation time.
