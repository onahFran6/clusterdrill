# q108-45: Fix an Ingress TLS block referencing the wrong Secret

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q108-45-ingress-tls-secretname-mismatch-fix`

Namespace `q108-45-ingress-tls-secretname-mismatch-fix` already has:

- a Deployment and Service `secure-app-svc` (port `80`)
- a valid TLS Secret named `secure-app-tls` (a self-signed cert/key pair for
  `secure.ckad.example.com`)
- an Ingress named `secure-app-ingress` with host `secure.ckad.example.com` routing `/` to
  `secure-app-svc:80`, and a `spec.tls` block whose `secretName` does not match any Secret that
  exists. TLS for this host cannot be terminated.

Fix the Ingress's `spec.tls[0].secretName` so it references `secure-app-tls`. Do not modify the
Secret, and do not change the Ingress's host or path routing.

## Hint

Search kubernetes.io/docs for **"Ingress" "TLS"** - the Ingress concept page's TLS section shows
`spec.tls[].secretName` naming the `kubernetes.io/tls` Secret the controller reads `tls.crt` and
`tls.key` from. A name that does not match any Secret in the Ingress's own namespace means TLS
termination fails for that host. Compare the current `secretName` with the Secret that exists.
