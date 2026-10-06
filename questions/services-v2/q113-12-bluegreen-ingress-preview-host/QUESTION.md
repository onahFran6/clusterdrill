# q113-12: Blue/green with a preview host

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q113-12-bluegreen-ingress-preview-host`

Team Procyon runs `site-blue` and `site-green` behind Services `blue-svc` and `green-svc`, plus a
`fallback-svc` for unknown hosts.

- Create Ingress `procyon` (class `nginx`): a main host of your choice routes to `blue-svc`, a
  `preview.` subdomain of that same host routes to `green-svc`, and any other host falls back to
  `fallback-svc`.
- After "checking the preview", cut the main host over to `green-svc` without touching any
  Service or Deployment.

This cluster has no Ingress controller installed, so grading checks the Ingress object's final
fields only, not a live HTTP response through one.

## Hint

Search kubernetes.io/docs for **"Ingress" "Default backend"** - `kubectl create ingress` has a
flag for the backend that catches any host no rule matches. Cutting a host over afterward means
changing one backend in one existing rule - a JSON patch on that rule's index works without
touching anything else.
