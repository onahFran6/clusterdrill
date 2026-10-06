# q116-08: Two hosts, two certificates

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q116-08-two-hosts-two-certificates`

Services `alpha-svc` and `beta-svc` (both port `80`, with their matching Deployments) already
serve `a.orbit.local` and `b.orbit.local` respectively - each needs its own certificate.

- Generate two self-signed certificates and store them as TLS Secrets: `alpha-tls` for
  `a.orbit.local`, `beta-tls` for `b.orbit.local`.
- Create **one** Ingress `orbit` (class `nginx`) that terminates TLS for both hosts, each with its
  matching Secret, and routes each host's `/` to its own Service.
- (ungraded, Task narrative only) Record the HTTPS response and certificate subject you'd expect
  for each host.

This cluster's supported-cluster contract does not guarantee a working Ingress controller, so the
routing half of this task is graded on the Ingress's own fields. The certificates themselves are
graded for real: `openssl x509` has to decode each Secret's `tls.crt` and show that host as the
subject.

## Hint

Search kubernetes.io/docs for **"Ingress" "TLS"** - the TLS section shows `spec.tls` as a list:
each entry pairs a list of hosts with one `secretName`. `openssl req -x509` generates a
self-signed certificate in one command; `kubectl create secret tls` takes `--cert`/`--key`.
