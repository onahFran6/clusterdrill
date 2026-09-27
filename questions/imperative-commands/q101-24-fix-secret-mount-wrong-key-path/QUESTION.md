# q101-24: Fix a Secret volume mount that never becomes Ready

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q101-24-fix-secret-mount-wrong-key-path`

In namespace `q101-24-fix-secret-mount-wrong-key-path`, a Pod named `cert-server` is failing to
start. It is supposed to mount Secret `tls-creds` so that a single file appears at
`/etc/certs/cert.pem`, but something is wrong with the volume configuration.

Investigate with `kubectl describe pod cert-server`, then fix it imperatively (patch, regenerate,
or recreate - no hand-written manifest applied from a fresh YAML file). The fixed Pod must:

- Be named `cert-server`, in this namespace, `Running` and `Ready`.
- Mount the existing Secret `tls-creds` as a volume.
- Expose exactly one file from that Secret at path `/etc/certs/cert.pem`.
- That file's content must be the Secret's original `tls.crt` value (do not recreate the Secret
  with different data).

Verify with `kubectl exec cert-server -- cat /etc/certs/cert.pem`.

## Hint

Search kubernetes.io/docs for **"secrets as files from a pod"** - the Secrets concept page's
"Using Secrets as files from a Pod" section documents the `volumes[].secret.items[].key` /
`.path` mapping that controls exactly which Secret key lands at which file name.
