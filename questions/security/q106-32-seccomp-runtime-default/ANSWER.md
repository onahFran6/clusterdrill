# q106-32: reference solution

Doc: https://kubernetes.io/docs/tutorials/security/seccomp/

```sh
kubectl delete pod worker -n q106-32-seccomp-runtime-default --wait=true

kubectl apply -n q106-32-seccomp-runtime-default -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: worker
  labels:
    app: worker
spec:
  containers:
    - name: worker
      image: busybox:1.36
      command: ["sleep", "3600"]
      securityContext:
        seccompProfile:
          type: RuntimeDefault
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
EOF

kubectl wait --for=condition=Ready pod/worker -n q106-32-seccomp-runtime-default --timeout=60s
```
