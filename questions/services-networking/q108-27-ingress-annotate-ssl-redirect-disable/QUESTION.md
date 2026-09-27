# q108-27: Disable forced SSL redirect on an HTTP-only Ingress

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q108-27-ingress-annotate-ssl-redirect-disable`

A Service `docs-svc` and an Ingress named `docs-ingress`
(IngressClass `nginx`) already exist. The Ingress routes path `/` (`pathType: Prefix`) to
`docs-svc` port `80`, has no `spec.tls` section, and currently forces an SSL redirect.

Fix `docs-ingress` so it stops forcing that redirect:

- Set the annotation `nginx.ingress.kubernetes.io/force-ssl-redirect` to the string `"false"`.
- Do not add a `spec.tls` section.
- Leave the rest of the Ingress (rule, path, backend service/port) unchanged.

## Hint

Search kubernetes.io/docs for **"ingress-nginx annotations force-ssl-redirect"** - the
Ingress-Nginx Controller's annotations documentation lists
`nginx.ingress.kubernetes.io/force-ssl-redirect` under its TLS-related annotations. With no TLS
Secret configured, forcing the redirect sends every client to HTTPS on a host that can never
terminate TLS.
