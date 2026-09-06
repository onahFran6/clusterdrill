# q108-45-ingress-tls-secretname-mismatch-fix: Fix an Ingress TLS block referencing the wrong Secret

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q108-45-ingress-tls-secretname-mismatch-fix`

`setup.sh` already created, in namespace `q108-45-ingress-tls-secretname-mismatch-fix`:

- a Deployment and Service `secure-app-svc` (port `80`)
- a real, valid TLS Secret named `secure-app-tls` (a self-signed cert/key pair for
  `secure.ckad.example.com`)
- an Ingress named `secure-app-ingress` with host `secure.ckad.example.com` routing `/` to
  `secure-app-svc:80`, and a `spec.tls` block - but that block's `secretName` is
  `secure-app-tls-old`, a Secret that does not exist. Because the referenced Secret is missing,
  the ingress controller cannot terminate TLS for this host at all.

Fix the Ingress's `spec.tls[0].secretName` so it references the Secret that actually exists,
`secure-app-tls`. Do not modify the Secret itself, and do not change the Ingress's host or path
routing.

## Hint

Search kubernetes.io/docs for **"Ingress" "TLS"** - the Ingress concept page's TLS section shows
`spec.tls[].secretName` naming the `kubernetes.io/tls` Secret the controller reads `tls.crt`
and `tls.key` from for the hosts listed alongside it; a name that doesn't match any Secret in the
Ingress's own namespace means TLS termination silently fails for that host.
