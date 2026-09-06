# q105-21: reference solution

Doc: https://kubernetes.io/docs/concepts/policy/limit-range/

```sh
kubectl apply -n q105-21-limitrange-min-max-bounds -f - <<EOF
apiVersion: v1
kind: LimitRange
metadata:
  name: mem-bounds
spec:
  limits:
    - type: Container
      min:
        memory: 64Mi
      max:
        memory: 512Mi
EOF

kubectl apply -n q105-21-limitrange-min-max-bounds -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: bounded-app
spec:
  containers:
    - name: bounded-app
      image: nginx:1.25-alpine
      resources:
        requests:
          memory: 200Mi
EOF
```
