# q110-26-crd-webhook-validation-mismatch-namespace: reference solution

Doc: https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definition-versioning/

```sh
NS="q110-26-crd-webhook-validation-mismatch-namespace"

# Fix the manifest: maxUsers must satisfy [1,100], tier must be one of
# bronze/silver/gold. Apply the corrected manifest.
kubectl apply -f - <<EOF
apiVersion: limits.clusterdrill.io/v1
kind: Quota
metadata:
  name: team-quota
  namespace: $NS
spec:
  maxUsers: 100
  tier: gold
EOF
```
