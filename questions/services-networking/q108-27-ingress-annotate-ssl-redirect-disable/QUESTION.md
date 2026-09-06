# q108-27-ingress-annotate-ssl-redirect-disable: Disable forced SSL redirect on an HTTP-only Ingress

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q108-27-ingress-annotate-ssl-redirect-disable`

`setup.sh` already created a Service `docs-svc` and an Ingress named `docs-ingress`
(IngressClass `nginx`) that routes path `/` (`pathType: Prefix`) to `docs-svc` port `80`. The
Ingress has no `spec.tls` section at all - it is plain HTTP only - but it was created with the
annotation `nginx.ingress.kubernetes.io/force-ssl-redirect: "true"` already set. With no TLS
configured, this forces ingress-nginx to redirect every request to HTTPS on a host that can never
terminate TLS, producing an infinite redirect loop for every client.

Fix `docs-ingress` so it stops forcing an SSL redirect:

- Set the annotation `nginx.ingress.kubernetes.io/force-ssl-redirect` to the string `"false"` on
  the `docs-ingress` Ingress.
- Do not add a `spec.tls` section.
- Leave the rest of the Ingress (rule, path, backend service/port) unchanged.

## Hint

Search kubernetes.io/docs for **"ingress-nginx annotations force-ssl-redirect"** - the
Ingress-Nginx Controller's annotations documentation lists `nginx.ingress.kubernetes.io/force-ssl-redirect`
under its TLS-related annotations, including its default value and behavior.
