# q110-10: Define a namespaced MenuItem CRD

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-10-crd-scope-namespaced`

Create a CustomResourceDefinition named `menuitems.diner.clusterdrill.io` with:

- group `diner.clusterdrill.io`, version `v1`, scope `Namespaced`
- plural `menuitems`, singular `menuitem`, kind `MenuItem`, listKind `MenuItemList`
- short name `mi`
- an OpenAPI v3 schema whose `spec` object has a required string property `dish`

Label the CRD `clusterdrill-question: q110-10-crd-scope-namespaced`. Also create one instance
named `special-1` in namespace `q110-10-crd-scope-namespaced` with `spec.dish` set to `ramen`.

## Hint

Search kubernetes.io/docs for **"customresourcedefinition shortNames"** - the CRD API
reference's `names` field documents `shortNames`, the same mechanism built-in resources use for
abbreviations like `po` for pods. Once registered, the instance should be listable as
`kubectl get mi`.
