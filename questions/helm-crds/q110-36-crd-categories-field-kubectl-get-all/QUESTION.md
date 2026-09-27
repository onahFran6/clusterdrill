# q110-36-crd-categories-field-kubectl-get-all: Make custom resources show up under `kubectl get all`

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-36-crd-categories-field-kubectl-get-all`

A CustomResourceDefinition `widgets.catalog.clusterdrill.io` (kind *Widget*, plural `widgets`,
group `catalog.clusterdrill.io/v1`, namespaced) is registered, and a *Widget* named `gadget-1`
exists in this namespace. `kubectl get all` in this namespace does not list that instance.

Patch the CRD so *Widget* is included in the `all` category (`spec.names.categories`), then
confirm `kubectl get all` lists *Widget* instances. Leave `gadget-1` unchanged.

## Hint

Search kubernetes.io/docs for **"CustomResourceDefinition" "categories"** - the CRD docs' Advanced
Features section explains `spec.names.categories` as the field that opts a custom resource kind
into being listed by `kubectl get <category>` for a category name like `all`.
