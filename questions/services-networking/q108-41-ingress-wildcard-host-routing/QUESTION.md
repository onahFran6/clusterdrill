# q108-41-ingress-wildcard-host-routing: Route every tenant subdomain with a wildcard Ingress host

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q108-41-ingress-wildcard-host-routing`

`setup.sh` already created a Deployment and a Service named `tenant-portal-svc` (port `80`) in
namespace `q108-41-ingress-wildcard-host-routing`. Every tenant of this SaaS product gets their own
subdomain (`acme.tenants.example.com`, `globex.tenants.example.com`, and so on), and all of them
must route to the same backend.

Create an Ingress named `tenant-portal-ingress` that:

- uses IngressClass `nginx`
- has a single rule with host `*.tenants.example.com` (a wildcard covering exactly one DNS label)
- routes path `/` with `pathType: Prefix` to `tenant-portal-svc` port `80`

## Hint

Search kubernetes.io/docs for **"Ingress" "wildcard"** - the Ingress concept page's Hostname
wildcards section shows a leading `*.` in `spec.rules[].host` matching any single DNS label in
that position, so `*.tenants.example.com` matches `acme.tenants.example.com` but not
`a.b.tenants.example.com`.
