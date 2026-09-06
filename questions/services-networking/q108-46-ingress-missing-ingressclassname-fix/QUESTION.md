# q108-46-ingress-missing-ingressclassname-fix: Fix an Ingress pointed at a nonexistent IngressClass

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q108-46-ingress-missing-ingressclassname-fix`

`setup.sh` already created a Deployment and Service `reports-svc` (port `80`), plus an Ingress
named `reports-ingress` in namespace `q108-46-ingress-missing-ingressclassname-fix` with a host
rule for `reports.ckad.example.com` routing `/` to `reports-svc:80`. A support ticket reports that
requests to this host get no response at all, not even an error page.

The Ingress object itself looks correctly formed - the bug is `spec.ingressClassName`. It is set
to `nginx-controller`, but no such IngressClass exists on this cluster (only `nginx` does).
`kubectl get ingress` still shows the object as valid and accepted (the API server does not
validate that `ingressClassName` refers to an IngressClass that actually exists), but no
controller ever claims it, so it is silently never processed.

Fix `reports-ingress` by setting `spec.ingressClassName` to the IngressClass that actually exists
on this cluster, `nginx`. Do not change the host, path, or backend.

## Hint

Search kubernetes.io/docs for **"IngressClass"** - the Ingress concept page's IngressClass section
explains that `spec.ingressClassName` must name a real `IngressClass` object for a controller to
claim the Ingress; a value that doesn't match any existing `IngressClass` leaves the Ingress
permanently unprocessed with no error surfaced anywhere.
