# q108-33: Fix a mismatched TLS certificate on a multi-host Ingress

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q108-33-ingress-multihost-tls-precedence`

Namespace `q108-33-ingress-multihost-tls-precedence` already has:

- Deployments `shop-web` and `shop-api`, each fronted by a ClusterIP Service (`shop-web-svc` and
  `shop-api-svc`, both port `80`).
- Two `kubernetes.io/tls` Secrets: `shop-web-tls` (cert issued for `shop.example.local`) and
  `shop-api-tls` (cert issued for `api.shop.example.local`).
- A single Ingress named `shop-ingress` (IngressClass `nginx`) with two host rules:
  - `shop.example.local` -> `shop-web-svc` port `80`
  - `api.shop.example.local` -> `shop-api-svc` port `80`

Both hosts' HTTP routing is correct. HTTPS for `api.shop.example.local` is served with a
certificate that does not match that host.

Fix `shop-ingress` so **both** hosts terminate TLS with their own matching Secret:

- `shop.example.local` -> Secret `shop-web-tls`
- `api.shop.example.local` -> Secret `shop-api-tls`

Do not change `spec.rules` and do not modify either Secret. Fix only the `spec.tls` mapping.

## Hint

Search kubernetes.io/docs for **"Ingress TLS"** - the Ingress concept page's TLS section shows
that `spec.tls` is a list, and each entry's `secretName` must hold the certificate for the hosts
listed in that same entry. A Secret that does not cover the requested host is not used for it;
ingress-nginx then falls back to its default certificate.

To see which certificate a host is served, from inside the cluster:

```sh
kubectl run tls-check --rm -it --restart=Never --image=curlimages/curl:8.10.1 -- \
  curl -sk -v --resolve api.shop.example.local:443:<ingress-nginx-controller-clusterip> \
  https://api.shop.example.local/ 2>&1 | grep subject:
```
