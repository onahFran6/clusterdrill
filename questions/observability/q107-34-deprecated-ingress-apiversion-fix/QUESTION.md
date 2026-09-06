# q107-34: Fix an Ingress manifest using a removed apiVersion and field shape

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-34-deprecated-ingress-apiversion-fix`

`setup.sh` already created a Service named `storefront-svc` (port 80) and wrote a manifest file to
`$HOME/practice-work/q107-34-deprecated-ingress-apiversion-fix/q107-34-ingress.yaml` (this
question's terminal working directory) for an `Ingress` named `storefront-ingress` routing host
`storefront.example.com`, path `/`, to `storefront-svc:80`. The manifest still declares
`apiVersion: extensions/v1beta1` and its old flat `backend.serviceName`/`backend.servicePort`
shape - both removed from Kubernetes entirely. Applying the file as-is fails.

Fix the manifest and create the `Ingress` in namespace `q107-34-deprecated-ingress-apiversion-fix`:

- change `apiVersion` to the current API group/version for `Ingress`
- update the backend to the current nested field shape, and add the now-required `pathType`
- keep the name `storefront-ingress`, host `storefront.example.com`, path `/`, and target
  `storefront-svc` port `80` exactly as described above

## Hint

Search kubernetes.io/docs for **"Ingress rules"** - the Ingress concept page's current examples
show `networking.k8s.io/v1`'s nested `backend.service.name`/`backend.service.port.number` shape
and the required `pathType` field, in contrast to the old flat `extensions/v1beta1` fields.
