# q116-01: Exact or Prefix?

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q116-01-exact-or-prefix`

Two Deployments and their matching ClusterIP Services already exist in this namespace, each a
`hashicorp/http-echo` instance that answers every request with its own name:

- `docs` (Service `docs-svc`, port `80`)
- `home` (Service `home-svc`, port `80`)

Create an Ingress named `meteor`, using IngressClass `nginx`, host `meteor.local`:

- exactly `/docs` routes to `docs-svc` port `80`
- everything else routes to `home-svc` port `80`

(ungraded, Task narrative only) Before you apply anything, predict which Service would answer each
of `/docs`, `/docs/`, `/docs/intro`, and `/docsx` under your planned rules.

## Hint

Search kubernetes.io/docs for **"pathType"** - the Ingress concept page's path-types table draws
the line between `Exact` (character-for-character) and `Prefix` (matched element by element,
split on `/`). Does a trailing slash change a character-for-character comparison?
