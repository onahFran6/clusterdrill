# q110-43-crd-structural-schema-pruning: Add a missing schema field so it stops getting rejected or silently dropped

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-43-crd-structural-schema-pruning`

`setup.sh` already registered a CustomResourceDefinition `profiles.people.clusterdrill.io`
(kind `Profile`, plural `profiles`, group `people.clusterdrill.io/v1`, namespaced) whose schema
only declares `spec.displayName` (string), and created an instance `alice` in namespace
`q110-43-crd-structural-schema-pruning` with `spec.displayName: "Alice"`. A teammate tried to add
a `spec.timezone` field to this same instance and hit one of two outcomes depending on how they
applied it: with normal (strict) validation, the API server rejected the whole request outright
("strict decoding error: unknown field"); with validation disabled
(`kubectl apply --validate=false`), the request was silently **accepted** but the unrecognized
`timezone` field was pruned before being stored - either way, `timezone` never actually landed on
the object.

The real fix is neither of those - it's making `timezone` a field the schema actually knows
about. Patch the CRD so `spec.timezone` (string, optional) is added to the schema. Then update
the `alice` instance to set `spec.timezone: "America/New_York"`, and confirm it actually persists
this time (not pruned, not rejected). Do not change `spec.displayName`'s schema or the instance's
`displayName` value.

## Hint

Search kubernetes.io/docs for **"CustomResourceDefinition" "pruning"** - the CRD docs' Pruning
section explains that a structural schema (the default and required shape since
`apiextensions.k8s.io/v1`) either rejects or strips any field not explicitly declared in
`properties` - the schema itself is the only real fix, not a client-side validation flag.
