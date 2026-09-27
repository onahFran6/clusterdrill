# q106-39: Lock down a container's privilege escalation

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-39-allowprivilegeescalation-false`

A running Pod named `web-worker` (image `nginx:1.25-alpine`) already exists. Its container does
not set `securityContext.allowPrivilegeEscalation`.

Without changing the image or any other container field, set the container's
`allowPrivilegeEscalation` to `false` and leave `web-worker` Running.

## Hint

Search kubernetes.io/docs for **"set the security context for a container"** - the security
context task page covers `allowPrivilegeEscalation`. When the field is omitted, privilege
escalation is allowed. The field can only be set when the container is created, so recreate the
Pod under the same name if a live edit is rejected.
