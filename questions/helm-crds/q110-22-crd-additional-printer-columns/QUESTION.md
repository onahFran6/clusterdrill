# q110-22-crd-additional-printer-columns: Add additional printer columns to a CRD and verify kubectl get output

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-22-crd-additional-printer-columns`

`setup.sh` registered a CRD named `invoices.billing.clusterdrill.io` (kind `Invoice`, plural
`invoices`, group `billing.clusterdrill.io/v1`, namespaced) with no `additionalPrinterColumns`,
and created two `Invoice` instances in namespace `q110-22-crd-additional-printer-columns`:
`inv-1001` (`spec.amount: 250`, `spec.status: paid`) and `inv-1002` (`spec.amount: 900`,
`spec.status: pending`). Right now `kubectl get invoices` in that namespace shows only the
default `NAME` and `AGE` columns.

Edit the existing CRD `invoices.billing.clusterdrill.io` (with `kubectl edit crd ...` or by
applying a patched manifest) to add two `additionalPrinterColumns` entries under its `v1`
version:

- a column named `Amount`, type `integer`, `jsonPath: .spec.amount`
- a column named `Status`, type `string`, `jsonPath: .spec.status`

Do not delete or recreate the CRD, and do not delete or recreate either `Invoice` instance -
only add the printer columns. After your change, `kubectl get invoices -n
q110-22-crd-additional-printer-columns` must show `AMOUNT` and `STATUS` columns with values `250`
/ `paid` for `inv-1001` and `900` / `pending` for `inv-1002`.

## Hint

Search kubernetes.io/docs for **"additionalPrinterColumns"** - the Custom Resources /
Extend the Kubernetes API with CustomResourceDefinitions page shows how to add extra
columns to a CRD's `spec.versions[].additionalPrinterColumns` list, and that `kubectl get`
picks these up automatically once the CRD is updated.
