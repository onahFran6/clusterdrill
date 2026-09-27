# q105-18: Mount a Secret with restrictive file permissions

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q105-18-secret-volume-default-mode`

A generic Secret named `ssh-key` already exists with a key `id_rsa` (a placeholder private key
value), plus a running Pod named `deploy-agent` (image `nginx:1.25-alpine`), in namespace
`q105-18-secret-volume-default-mode`.

Edit the pod so its container mounts `ssh-key` as a volume at `/etc/ssh-key`, with the mounted
file's permission bits set to `0400` (owner read-only - private keys should never be
group/world-readable). The pod will need to be recreated for the mount to take effect.

Verify with `kubectl exec deploy-agent -- ls -l /etc/ssh-key/id_rsa` - the mode should show
`r--------` (or equivalent `0400`).

## Hint

Search kubernetes.io/docs for **"secret defaultMode"** - the Secrets concept page's volume
example shows the `defaultMode` field takes a decimal number representing an octal permission
value (`0400` decimal `256`), applied to every file projected from that Secret.
