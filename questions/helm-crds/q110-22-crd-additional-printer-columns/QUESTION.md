# q110-22-crd-additional-printer-columns: Add additional printer columns to a CRD and verify kubectl get output

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-22-crd-additional-printer-columns`

A CRD named `invoices.billing.clusterdrill.io` (kind `Invoice`, plural `invoices`, group
`billing.clusterdrill.io/v1`, namespaced) is registered without custom printer columns.
Two Invoice instances exist in this namespace: `inv-1001` (`spec.amount: 250`,
`spec.status: paid`) and `inv-1002` (`spec.amount: 900`, `spec.status: pending`).
`kubectl get invoices` currently shows only the default `NAME` and `AGE` columns.

Update the existing CRD so its `v1` version gains two additional printer columns:

- `Amount` (type `integer`, `jsonPath: .spec.amount`)
- `Status` (type `string`, `jsonPath: .spec.status`)

Do not delete or recreate the CRD or either Invoice. After the change,
`kubectl get invoices -n q110-22-crd-additional-printer-columns` must show `AMOUNT` and
`STATUS` columns with `250` / `paid` for `inv-1001` and `900` / `pending` for `inv-1002`.

## Hint

Search kubernetes.io/docs for **"additionalPrinterColumns"** - the Custom Resources /
Extend the Kubernetes API with CustomResourceDefinitions page shows how to add extra
columns under `spec.versions[].additionalPrinterColumns`, and that `kubectl get` picks these
up automatically once the CRD is updated.
