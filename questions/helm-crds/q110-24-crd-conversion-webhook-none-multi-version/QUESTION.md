# q110-24-crd-conversion-webhook-none-multi-version: Add a new served CRD version without breaking existing stored instances

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-24-crd-conversion-webhook-none-multi-version`

A CustomResourceDefinition `reports.analytics.clusterdrill.io` (group `analytics.clusterdrill.io`,
kind `Report`, plural `reports`) exists with a single version `v1beta1` (`served: true`,
`storage: true`). Its schema requires `spec.title` (string). An instance named `q3-summary`
exists in this namespace with `spec.title: "Q3 Summary"`.

Patch the CRD to additionally define version `v1`:

- `v1`: `served: true`, `storage: false`
- `v1beta1`: remain `served: true`, `storage: true`
- `v1` schema must require `spec.title` as a string, matching `v1beta1`

Do not delete the CRD or recreate `q3-summary`. After the patch, the instance must be readable
through both version paths with `spec.title: Q3 Summary`
(`reports.v1beta1.analytics.clusterdrill.io` and `reports.v1.analytics.clusterdrill.io`).

## Hint

Search kubernetes.io/docs for **"Versions in CustomResourceDefinitions"** - with conversion
strategy `None` (the default when no webhook is configured), only one version may be the
storage version at a time, and identical schemas let existing objects stay readable on both
served versions.
