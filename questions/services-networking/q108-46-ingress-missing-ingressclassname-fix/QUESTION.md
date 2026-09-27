# q108-46: Fix an Ingress pointed at a nonexistent IngressClass

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q108-46-ingress-missing-ingressclassname-fix`

A Deployment and Service `reports-svc` (port `80`), plus an Ingress
named `reports-ingress`, already exist in namespace
`q108-46-ingress-missing-ingressclassname-fix`. The Ingress has a host rule for
`reports.ckad.example.com` routing `/` to `reports-svc:80`. Requests to this host get no
response at all, not even an error page.

The host, path, and backend are correct. `spec.ingressClassName` does not name an IngressClass
that exists on this cluster.

Fix `reports-ingress` by setting `spec.ingressClassName` to `nginx`. Do not change the host,
path, or backend.

## Hint

Search kubernetes.io/docs for **"IngressClass"** - the Ingress concept page's IngressClass section
explains that `spec.ingressClassName` must name a real `IngressClass` for a controller to claim
the Ingress. The API server accepts a name that matches nothing, so `kubectl get ingress` still
shows the object, and no controller ever processes it. List IngressClasses and compare them with
the current value.
