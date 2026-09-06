# q108-33-ingress-multihost-tls-precedence: Fix a mismatched TLS certificate on a multi-host Ingress

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q108-33-ingress-multihost-tls-precedence`

`setup.sh` already created, in namespace `q108-33-ingress-multihost-tls-precedence`:

- Deployments `shop-web` and `shop-api`, each fronted by a ClusterIP Service (`shop-web-svc` and
  `shop-api-svc`, both port `80`).
- Two `kubernetes.io/tls` Secrets: `shop-web-tls` (cert issued for `shop.example.local`) and
  `shop-api-tls` (cert issued for `api.shop.example.local`).
- A single Ingress named `shop-ingress` (IngressClass `nginx`) with two host rules:
  - `shop.example.local` -> `shop-web-svc` port `80`
  - `api.shop.example.local` -> `shop-api-svc` port `80`

Both hosts' HTTP routing is correct. The Ingress's `spec.tls` block, however, was copy-pasted
when the second host was added and the `secretName` for `api.shop.example.local` was never
updated - it still points at `shop-web-tls` (the certificate issued for `shop.example.local`,
which has no `api.shop.example.local` entry in its subject/SAN). Because ingress-nginx will not
serve a certificate that doesn't cover the host being requested, it falls back to its own
self-signed default certificate for `api.shop.example.local` instead - so HTTPS requests to that
host complete, but with the wrong (non-matching) certificate.

Fix `shop-ingress` so **both** hosts terminate TLS with their own matching Secret:

- `shop.example.local` -> Secret `shop-web-tls`
- `api.shop.example.local` -> Secret `shop-api-tls`

Do not change `spec.rules` (the HTTP host-to-backend routing is already correct) and do not
modify either Secret - fix only the `spec.tls` mapping in the Ingress.

You can inspect which certificate a host is actually being served, from inside the cluster,
with something like:

```sh
kubectl run tls-check --rm -it --restart=Never --image=curlimages/curl:8.10.1 -- \
  curl -sk -v --resolve api.shop.example.local:443:<ingress-nginx-controller-clusterip> \
  https://api.shop.example.local/ 2>&1 | grep subject:
```

## Hint

Search kubernetes.io/docs for **"Ingress TLS"** - the Ingress concept page's TLS section shows
that `spec.tls` is a list, where each entry's `secretName` must hold the certificate for the
hosts listed in that same entry's `hosts` field. A Secret that doesn't cover the requested host
is not used for it.
