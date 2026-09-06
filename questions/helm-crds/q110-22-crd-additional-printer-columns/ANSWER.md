# q110-22-crd-additional-printer-columns: reference solution

Doc: https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/#additional-printer-columns

```sh
kubectl patch crd invoices.billing.clusterdrill.io --type='json' -p='[
  {
    "op": "add",
    "path": "/spec/versions/0/additionalPrinterColumns",
    "value": [
      {
        "name": "Amount",
        "type": "integer",
        "jsonPath": ".spec.amount"
      },
      {
        "name": "Status",
        "type": "string",
        "jsonPath": ".spec.status"
      }
    ]
  }
]'

kubectl wait --for=condition=Established crd/invoices.billing.clusterdrill.io --timeout=60s

kubectl get invoices -n q110-22-crd-additional-printer-columns
```
