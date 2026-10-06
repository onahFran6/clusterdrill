# q114-07: reference solution

Doc: https://kubernetes.io/docs/concepts/storage/persistent-volumes/#class-1

```sh
NS=q114-07-dynamic-by-default-static-on-purpose

kubectl apply -n "$NS" -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: dyn
  labels:
    clusterdrill-question: $NS
spec:
  accessModes: ["ReadWriteOnce"]           # no storageClassName: the default class fills in
  resources:
    requests:
      storage: 200Mi
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: stat
  labels:
    clusterdrill-question: $NS
spec:
  storageClassName: ""                     # explicitly no class: static-only, never provisioned
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 1Gi
---
apiVersion: v1
kind: Pod
metadata:
  name: seine-app
  labels:
    clusterdrill-question: $NS
spec:
  volumes:
    - name: a
      persistentVolumeClaim:
        claimName: dyn
    - name: b
      persistentVolumeClaim:
        claimName: stat
  containers:
    - name: app
      image: busybox:1.36
      command: ["sleep", "3600"]
      volumeMounts:
        - { name: a, mountPath: /dyn }
        - { name: b, mountPath: /stat }
EOF

kubectl wait --for=condition=Ready pod/seine-app -n "$NS" --timeout=60s
kubectl get pvc -n "$NS" -o custom-columns=N:.metadata.name,C:.spec.storageClassName,V:.spec.volumeName
```

The default class is written into the claim the instant it's created (even though the manifest
never mentioned it), so `dyn` reports it afterwards. `stat`'s explicit empty string means "never
provision" and relies entirely on the pre-existing PV's `claimRef` pin to bind.
