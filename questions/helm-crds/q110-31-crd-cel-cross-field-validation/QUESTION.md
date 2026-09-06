# q110-31-crd-cel-cross-field-validation: Discover and satisfy a CEL cross-field validation rule on a CRD

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-31-crd-cel-cross-field-validation`

`setup.sh` registered a CustomResourceDefinition `budgets.finance.clusterdrill.io` (kind
`Budget`, plural `budgets`, group `finance.clusterdrill.io/v1`, namespaced). Its OpenAPI schema
requires `spec.limit` (integer, `minimum: 1`) and `spec.reserved` (integer, `minimum: 0`) - but
the schema also carries an additional CEL cross-field rule via `x-kubernetes-validations` that is
**not restated here**. A value for `spec.limit` and `spec.reserved` that individually satisfies
both fields' own bounds is not automatically accepted - the rule can still reject the combination.

Discover the rule yourself. `kubectl get crd budgets.finance.clusterdrill.io -o yaml`,
`kubectl explain budget.spec --recursive`, or simply attempting a create and reading the API
server's rejection message will all reveal it.

Once you know the rule, create an instance named `q4-cap` in namespace
`q110-31-crd-cel-cross-field-validation` with `spec.limit: 500` and `spec.reserved` set to the
**largest integer value that still satisfies the rule**.

Do not weaken the CRD's schema or remove the rule to make an otherwise-invalid object pass - the
rule must still reject `spec.reserved` values that violate it after your fix.

## Hint

Search kubernetes.io/docs for **"CustomResourceDefinition validation rules"** - the "Validation
rules" section of the CRD docs explains `x-kubernetes-validations` and how the CEL `self`
variable refers to the schema node the rule is attached to, which is exactly how a rule can
compare two sibling fields against each other.
