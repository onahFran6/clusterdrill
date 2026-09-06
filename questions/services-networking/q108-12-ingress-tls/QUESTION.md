# q108-12: Terminate TLS at the Ingress with a Secret

**Domain:** Services and Networking · **Points:** 7 · **Namespace:** `q108-12-ingress-tls`

`setup.sh` already created a Deployment `secure-app` and a matching ClusterIP Service
`secure-app-svc` (port `80`), plus a `kubernetes.io/tls` Secret named `secure-app-tls` (a
self-signed cert/key pair for host `secure.ckad.example.com`) - all in namespace
`q108-12-ingress-tls`.

Create an Ingress named `secure-ingress` in this namespace, using IngressClass `nginx`, that:

- routes all paths (`/`, `pathType: Prefix`) for host `secure.ckad.example.com` to
  `secure-app-svc` port `80`
- terminates TLS for that same host using the existing `secure-app-tls` Secret

## Hint

Search kubernetes.io/docs for **"Ingress TLS"** - the Ingress concept page's TLS section shows the
`spec.tls[].hosts` and `spec.tls[].secretName` fields that tell the Ingress controller which
Secret to use for which host.
