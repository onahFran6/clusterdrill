# q107-39-multiple-init-containers-sequential-failure: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/pods/init-containers/#detailed-behavior

Diagnose which init container is actually failing (they run in order, one at a time):

```sh
kubectl describe pod report-builder -n q107-39-multiple-init-containers-sequential-failure
kubectl logs report-builder -n q107-39-multiple-init-containers-sequential-failure -c fetch-config
```

Init container command/args are set at Pod creation time and cannot be patched onto a running Pod
- delete and recreate it with `fetch-config` fixed.

```sh
kubectl delete pod report-builder -n q107-39-multiple-init-containers-sequential-failure --wait=true

kubectl apply -n q107-39-multiple-init-containers-sequential-failure -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: report-builder
  labels:
    app: report-builder
spec:
  initContainers:
    - name: create-workdir
      image: busybox:1.36
      command: ["sh", "-c", "mkdir -p /work/data && echo workdir-ready"]
    - name: fetch-config
      image: busybox:1.36
      command: ["sh", "-c", "echo fetch-config-ok"]
    - name: validate-config
      image: busybox:1.36
      command: ["sh", "-c", "echo config-valid"]
  containers:
    - name: report-builder
      image: nginx:1.25-alpine
EOF

kubectl wait --for=condition=Ready pod/report-builder -n q107-39-multiple-init-containers-sequential-failure --timeout=60s
```
