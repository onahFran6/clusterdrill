# q106-43: Diagnose and fix a Pod rejected by the 'restricted' Pod Security Standard

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q106-43-podsecurity-restricted-rejects-root`

`setup.sh` tried to create a Pod named `audit-runner` (image `busybox:1.36`, command
`sleep 3600`) in this namespace, but it was rejected - the namespace enforces the `restricted`
Pod Security Standard, and the Pod's spec has no security hardening at all. Recreate `audit-runner`
so it satisfies `restricted` and reaches `Running`, without loosening the namespace's enforcement
level.

## Hint

Search kubernetes.io/docs for **"Pod Security Standards"** - the concept page lists exactly what
the `restricted` level requires beyond `baseline`: `runAsNonRoot`, disallowed privilege escalation,
a `RuntimeDefault`/`Localhost` seccomp profile, and all capabilities dropped.
