# q107-49-diagnose-two-simultaneous-crashloops-different-causes: reference solution

Doc: https://kubernetes.io/docs/tasks/debug/debug-application/determine-reason-pod-failure/

Diagnose each independently:

```sh
kubectl describe pod worker-a -n q107-49-diagnose-two-simultaneous-crashloops-different-causes
# -> reason: exec: "sleeep": executable file not found in $PATH

kubectl describe pod worker-b -n q107-49-diagnose-two-simultaneous-crashloops-different-causes
# -> last state terminated reason: OOMKilled
```

Both pods' container fields are set at creation time and can't be patched onto a running Pod -
delete and recreate each with its own fix.

```sh
kubectl delete pod worker-a worker-b -n q107-49-diagnose-two-simultaneous-crashloops-different-causes --wait=true

kubectl apply -n q107-49-diagnose-two-simultaneous-crashloops-different-causes -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: worker-a
  labels:
    app: worker-a
spec:
  containers:
    - name: worker-a
      image: busybox:1.36
      command: ["sleep", "3600"]
---
apiVersion: v1
kind: Pod
metadata:
  name: worker-b
  labels:
    app: worker-b
spec:
  containers:
    - name: worker-b
      image: polinux/stress
      command: ["stress"]
      args: ["--vm", "1", "--vm-bytes", "150M", "--vm-hang", "1"]
      resources:
        limits:
          memory: "250Mi"
        requests:
          memory: "250Mi"
EOF

kubectl wait --for=condition=Ready pod/worker-a pod/worker-b -n q107-49-diagnose-two-simultaneous-crashloops-different-causes --timeout=60s
```
