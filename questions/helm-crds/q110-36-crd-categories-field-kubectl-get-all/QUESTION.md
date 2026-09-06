# q110-36-crd-categories-field-kubectl-get-all: Make custom resources show up under `kubectl get all`

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-36-crd-categories-field-kubectl-get-all`

`setup.sh` already registered a CustomResourceDefinition `widgets.catalog.clusterdrill.io`
(kind `Widget`, plural `widgets`, group `catalog.clusterdrill.io/v1`, namespaced) and created an
instance named `gadget-1` in namespace `q110-36-crd-categories-field-kubectl-get-all`. Running
`kubectl get all -n q110-36-crd-categories-field-kubectl-get-all` does **not** list `gadget-1` -
`kubectl get all` only shows resource kinds whose CRD declares itself a member of the `all`
category, and this CRD's `spec.names.categories` is currently empty.

Patch the CRD so `spec.names.categories` includes `all`, so `kubectl get all` in this namespace
starts listing `Widget` instances alongside Pods, Services, and everything else it already
covers. Do not touch the existing `gadget-1` instance.

## Hint

Search kubernetes.io/docs for **"CustomResourceDefinition" "categories"** - the CRD docs' Advanced
Features section explains `spec.names.categories` as the field that opts a custom resource kind
into being listed by `kubectl get <category>` for a category name like `all`.
