# q112-11: reference solution

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/security-context/

```sh
NS=q112-11-locked-down-security-context

cat <<EOF | kubectl apply -n "$NS" -f -
apiVersion: v1
kind: Pod
metadata:
  name: locked
  labels:
    clusterdrill-question: $NS
spec:
  securityContext:
    runAsUser: 1000
    runAsGroup: 3000
    fsGroup: 2000
  volumes:
    - name: data
      emptyDir: {}
  containers:
    - name: app
      image: busybox:1.36
      command: ["sleep", "3600"]
      securityContext:
        readOnlyRootFilesystem: true
        allowPrivilegeEscalation: false
        capabilities:
          drop: ["ALL"]
      volumeMounts:
        - name: data
          mountPath: /data
EOF

kubectl wait --for=condition=Ready pod/locked -n "$NS" --timeout=60s
kubectl exec locked -n "$NS" -- id
kubectl exec locked -n "$NS" -- sh -c 'touch /data/f; ls -ln /data/f'
```

`fsGroup` sets group ownership on supported volumes and adds that group to every container's
process, so it belongs at the Pod level where it affects all containers uniformly.
`capabilities`, `readOnlyRootFilesystem` and `allowPrivilegeEscalation` only exist on the
container's own `securityContext` - putting any of them under `spec.securityContext` fails
validation outright, it is not just ignored.
