# q110-31-crd-cel-cross-field-validation: Discover and satisfy a CEL cross-field validation rule on a CRD

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-31-crd-cel-cross-field-validation`

A CustomResourceDefinition `budgets.finance.clusterdrill.io` (kind *Budget*, plural
`budgets`, group `finance.clusterdrill.io/v1`, namespaced) is registered. Its schema requires
`spec.limit` (integer, minimum `1`) and `spec.reserved` (integer, minimum `0`). Values that
meet those per-field bounds can still be rejected together by an additional cross-field rule on
the CRD - that rule is not restated here; inspect the CRD or try a create to learn it.

Create a *Budget* named `q4-cap` in this namespace with `spec.limit: 500` and `spec.reserved`
set to the largest integer that still satisfies the rule. Do not weaken or remove the CRD's
validation rule.

## Hint

Search kubernetes.io/docs for **"CustomResourceDefinition validation rules"** - the "Validation
rules" section of the CRD docs explains `x-kubernetes-validations` and how the CEL `self`
variable refers to the schema node the rule is attached to, which is exactly how a rule can
compare two sibling fields against each other.
