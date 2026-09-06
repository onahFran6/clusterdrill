# q110-07: Define a CustomResourceDefinition with a validation schema

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-07-crd-define-schema`

Create a `CustomResourceDefinition` named `coffeeorders.snacks.clusterdrill.io` with:

- group `snacks.clusterdrill.io`, version `v1`, scope `Namespaced`
- plural `coffeeorders`, singular `coffeeorder`, kind `CoffeeOrder`, listKind `CoffeeOrderList`
- an OpenAPI v3 schema (`served: true`, `storage: true`) whose `spec` object has a **required**
  string property named `size`

Label the CRD itself `clusterdrill-question: q110-07-crd-define-schema` (cluster-scoped
objects need this label too, the same as namespaced ones).

You do not need to create any instance of this resource - only the definition.

## Hint

Search kubernetes.io/docs for **"custom resource definitions"** - the CRD concept page has a
full example manifest showing `spec.versions[].schema.openAPIV3Schema` and how to mark a
property `required`.

