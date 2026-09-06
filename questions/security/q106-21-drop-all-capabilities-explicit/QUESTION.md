# q106-21-drop-all-capabilities-explicit: Drop ALL Linux capabilities on a container

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-21-drop-all-capabilities-explicit`

`setup.sh` already created a running pod named `audit-agent` (image `busybox:1.36`, command
`sleep 3600`) in namespace `q106-21-drop-all-capabilities-explicit`. Its container has no
`securityContext` set at all, so it keeps the full default Linux capability set granted by the
container runtime, which a security audit flagged.

Edit the pod (recreating it under the same name if needed) so the container's
`securityContext.capabilities.drop` is set to `["ALL"]` and nothing is added back. Do not change
the image or command, and confirm the pod reaches `Running` afterward.

## Hint

Search kubernetes.io/docs for **"configure a security context for a pod or container"** - the
task page shows the `capabilities.drop` list shape used to drop every Linux capability from a
container.
