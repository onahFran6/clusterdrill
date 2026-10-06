# q114-01: reference solution

Doc: https://kubernetes.io/docs/concepts/storage/persistent-volumes/#selector

```sh
NS=q114-01-pick-the-fast-volume

kubectl apply -n "$NS" -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: nile-data
  labels:
    clusterdrill-question: $NS
spec:
  storageClassName: manual-q114-01
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 1Gi
  selector:
    matchLabels:
      tier: fast
---
apiVersion: v1
kind: Pod
metadata:
  name: nile-app
  labels:
    clusterdrill-question: $NS
spec:
  volumes:
    - name: data
      persistentVolumeClaim:
        claimName: nile-data
  containers:
    - name: app
      image: busybox:1.36
      command: ["sh", "-c", "echo hello nile > /data/msg; sleep 3600"]
      volumeMounts:
        - name: data
          mountPath: /data
EOF

kubectl wait --for=condition=Ready pod/nile-app -n "$NS" --timeout=60s
```

A claim with a `selector` can only bind to an existing PV - dynamic provisioners ignore it, and the
claim stays `Pending` if nothing matches.
