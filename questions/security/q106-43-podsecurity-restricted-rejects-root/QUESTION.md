# q106-43: Diagnose and fix a Pod rejected by the 'restricted' Pod Security Standard

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-43-podsecurity-restricted-rejects-root`

Namespace `q106-43-podsecurity-restricted-rejects-root` enforces the `restricted` Pod Security
Standard. A Pod named `audit-runner` (image `busybox:1.36`, command `sleep 3600`) was not
admitted. Recreate `audit-runner` so it satisfies `restricted` and reaches `Running`. Label it
`app: audit-runner`. Do not loosen the namespace's enforcement level.

## Hint

Search kubernetes.io/docs for **"Pod Security Standards"** - the concept page lists what
`restricted` requires beyond `baseline`: `runAsNonRoot`, `allowPrivilegeEscalation: false`, a
`RuntimeDefault` or `Localhost` seccomp profile, and all capabilities dropped. Image
`busybox:1.36` defaults to UID 0, so set a non-root `runAsUser` as well or the Pod will not
reach `Running`.
