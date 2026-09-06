# q110-35-crd-schema-default-value: reference solution

Doc: https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/#defaulting

```sh
kubectl patch crd queues.jobs.clusterdrill.io \
  --type json \
  -p '[{"op":"add","path":"/spec/versions/0/schema/openAPIV3Schema/properties/spec/properties/priority/default","value":5}]'

kubectl apply -n q110-35-crd-schema-default-value -f - <<EOF
apiVersion: jobs.clusterdrill.io/v1
kind: Queue
metadata:
  name: batch-job
spec:
  name: batch-job
EOF
```
