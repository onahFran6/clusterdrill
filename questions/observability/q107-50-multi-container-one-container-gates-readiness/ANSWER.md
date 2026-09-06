# q107-50-multi-container-one-container-gates-readiness: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#pod-conditions

Diagnose which container is actually unready:

```sh
kubectl get pod web-stack -n q107-50-multi-container-one-container-gates-readiness \
  -o jsonpath='{range .status.containerStatuses[*]}{.name}{"="}{.ready}{"\n"}{end}'
```

Probe fields are set at container creation time and cannot be patched onto a running Pod - delete
and recreate it with only `cache` fixed.

```sh
kubectl delete pod web-stack -n q107-50-multi-container-one-container-gates-readiness --wait=true

kubectl apply -n q107-50-multi-container-one-container-gates-readiness -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: web-stack
  labels:
    app: web-stack
spec:
  containers:
    - name: frontend
      image: nginx:1.25-alpine
    - name: cache
      image: nginx:1.25-alpine
      readinessProbe:
        httpGet:
          path: /
          port: 80
        periodSeconds: 2
    - name: logger
      image: busybox:1.36
      command: ["sh", "-c", "sleep 3600"]
EOF

kubectl wait --for=condition=Ready pod/web-stack -n q107-50-multi-container-one-container-gates-readiness --timeout=60s
```
