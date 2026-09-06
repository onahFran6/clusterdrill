# q107-19: reference solution

Doc: https://kubernetes.io/docs/tasks/debug/debug-application/debug-pods/

```sh
kubectl delete pod catalog-api -n q107-19-describe-find-image-pull-error --ignore-not-found

kubectl apply -n q107-19-describe-find-image-pull-error -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: catalog-api
  labels:
    app: catalog-api
    clusterdrill-question: q107-19-describe-find-image-pull-error
spec:
  containers:
    - name: catalog-api
      image: nginx:1.25-alpine
EOF

kubectl wait --for=condition=Ready pod/catalog-api -n q107-19-describe-find-image-pull-error --timeout=60s
```
