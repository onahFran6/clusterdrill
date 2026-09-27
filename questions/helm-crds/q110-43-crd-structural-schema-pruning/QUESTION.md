# q110-43-crd-structural-schema-pruning: Add a missing schema field so it stops getting rejected or silently dropped

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-43-crd-structural-schema-pruning`

A CustomResourceDefinition `profiles.people.clusterdrill.io` (kind `Profile`, plural
`profiles`, group `people.clusterdrill.io/v1`, namespaced) is installed. Its schema currently
declares only `spec.displayName` (string). Instance `alice` in this namespace has
`spec.displayName: "Alice"`. Attempts to set `spec.timezone` on `alice` do not persist.

Patch the CRD so `spec.timezone` (string, optional) is part of the schema. Then update `alice`
to `spec.timezone: "America/New_York"` and confirm the value sticks. Do not change
`spec.displayName`'s schema or `alice`'s `displayName` value.

## Hint

Search kubernetes.io/docs for **"CustomResourceDefinition" "pruning"** - the CRD docs' Pruning
section explains that a structural schema (the default and required shape since
`apiextensions.k8s.io/v1`) either rejects or strips any field not explicitly declared in
`properties` - the schema itself is the only real fix, not a client-side validation flag.
