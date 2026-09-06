# q103-15: reference solution

Doc: https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#nodeselector

```sh
kubectl apply -n q103-15-pod-nodeselector-os-linux -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: linux-only
  labels:
    clusterdrill-question: q103-15-pod-nodeselector-os-linux
spec:
  nodeSelector:
    kubernetes.io/os: linux
  containers:
    - name: linux-only
      image: busybox:1.36
      command: ["sleep", "3600"]
EOF
```
