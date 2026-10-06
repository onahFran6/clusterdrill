# q116-05: The default class came too late

**Domain:** Services and Networking · **Points:** 5 · **Namespace:** `q116-05-the-default-class-came-too-late`

Service `web-svc` (port `80`) is already running in this namespace, and Ingress `pulsar` already
exists, routing to it. An IngressClass named `q116-05-ingress-class` also already exists, but is
not yet the cluster's default.

- Make `q116-05-ingress-class` the cluster's default IngressClass: annotate it
  `ingressclass.kubernetes.io/is-default-class: "true"`.
- Get `pulsar` served by `q116-05-ingress-class`, without writing an `ingressClassName` into its
  YAML yourself. The admission step that fills in a default class only resolves at genuine
  object-creation time - never retroactively, and never a second time if the object already
  carries an explicit class of its own (including one filled in earlier by whatever class used to
  be default). Read `pulsar` back out, strip its `spec.ingressClassName` along with the usual
  server-managed fields (`status`, `metadata.uid`, `metadata.resourceVersion`, ...), and recreate
  it so the new default actually has a chance to apply.
- (ungraded, Task narrative only) Record the Ingress's CLASS column before and after.

## Hint

Search kubernetes.io/docs for **"IngressClass"** - the Ingress concept page's "Default
IngressClass" section explains exactly when the annotation's effect fires. Check
`kubectl get ingress pulsar -n <this namespace> -o yaml` before you start: does `spec` already
carry a class? If it does, where did that come from, and will annotating a different class as
default do anything to an object that already has one set?
