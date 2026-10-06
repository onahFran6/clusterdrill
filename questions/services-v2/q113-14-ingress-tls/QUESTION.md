# q113-14: HTTPS on the Ingress

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q113-14-ingress-tls`

Team Betelgeuse wants a host served over HTTPS by Service `secure-svc` (port 80, already
running).

- Pick a realistic-looking hostname (it never needs to resolve anywhere - it's just a string in
  the spec). Generate a self-signed certificate for it and store it as TLS Secret `secure-tls`.
- Create Ingress `secure` (class `nginx`) that terminates TLS for that host with that Secret, and
  routes `/` to `secure-svc:80`.

This cluster has no Ingress controller installed, so the routing half of this task is graded on
the object's fields only. The certificate itself is graded for real: `openssl x509` has to decode
it and show the host you chose as the certificate's subject.

## Hint

Search kubernetes.io/docs for **"Ingress" "TLS"** - the Ingress concept page's TLS section shows
`kubectl create secret tls` taking `--cert`/`--key`, and an Ingress's `spec.tls[].hosts` paired
with `secretName`. `openssl req -x509` generates a self-signed certificate in one command.
