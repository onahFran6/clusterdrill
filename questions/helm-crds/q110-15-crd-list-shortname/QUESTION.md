# q110-15: Count Coupons via the CRD's short name

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-15-crd-list-shortname`

A namespaced CRD (kind `Coupon`, plural `coupons`, group `retail.clusterdrill.io/v1`, short
name `cpn`) is already registered, and three `Coupon` instances exist in namespace
`q110-15-crd-list-shortname`: `spring-sale`, `flash-10`, and `vip-20`, each with a
`spec.discountPercent`.

Using the CRD's short name, confirm all three Coupon objects are visible. Then create a
ConfigMap named `coupon-count` in the same namespace with a key `total` set to the string
`3`, reflecting how many Coupon objects currently exist.

## Hint

Search kubernetes.io/docs for **"additionalPrinterColumns shortNames"** - the Custom Resources
/ Extend the Kubernetes API with CustomResourceDefinitions page documents `spec.names.shortNames`,
which lets `kubectl get cpn` resolve to Coupons the same way `kubectl get po` resolves to Pods.
