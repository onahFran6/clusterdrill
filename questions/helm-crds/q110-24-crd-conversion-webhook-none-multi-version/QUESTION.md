# q110-24-crd-conversion-webhook-none-multi-version: Add a new served CRD version without breaking existing stored instances

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-24-crd-conversion-webhook-none-multi-version`

A CustomResourceDefinition `reports.analytics.clusterdrill.io` (group `analytics.clusterdrill.io`, kind `Report`, plural `reports`) already exists with a single version `v1beta1` (`served: true`, `storage: true`). Its schema requires `spec.title` (string). An instance named `q3-summary` already exists in namespace `q110-24-crd-conversion-webhook-none-multi-version` with `spec.title: "Q3 Summary"`.

Patch the existing CRD to additionally define version `v1`:

- `v1` must have `served: true` and `storage: false`.
- `v1beta1` must remain `served: true` and `storage: true` (do not change its storage status - no conversion webhook is configured, so the CRD uses the default `None` conversion strategy, and only one version may be the storage version at a time).
- `v1`'s schema must require `spec.title` as a string, matching `v1beta1`'s schema exactly.

Do not delete the CRD and do not delete or recreate the `q3-summary` instance - it must survive the patch untouched. Since conversion strategy is `None` and the schemas are identical, the existing stored object must be readable through both version paths after the patch: `kubectl get reports.v1beta1.analytics.clusterdrill.io q3-summary` and `kubectl get reports.v1.analytics.clusterdrill.io q3-summary` (equivalently, `kubectl get report q3-summary -n q110-24-crd-conversion-webhook-none-multi-version --output=... ` with `apiVersion: analytics.clusterdrill.io/v1` in a manifest) must both succeed and show `spec.title: Q3 Summary`.

## Hint

Search kubernetes.io/docs for **"Versions in CustomResourceDefinitions"** - the section on adding a new version to an existing CRD (and why only one version can be the storage version without a conversion webhook) covers exactly this patch.
