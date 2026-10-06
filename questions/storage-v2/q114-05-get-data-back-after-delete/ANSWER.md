# q114-05: reference solution

Doc: https://kubernetes.io/docs/concepts/storage/persistent-volumes/#retain

```sh
NS=q114-05-get-data-back-after-delete

kubectl get pv q114-05-pv -o jsonpath='{.status.phase}'; echo   # Released

kubectl patch pv q114-05-pv --type=json -p='[{"op":"remove","path":"/spec/claimRef"}]'
kubectl get pv q114-05-pv   # Available

kubectl apply -n "$NS" -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: rhine-new
  labels:
    clusterdrill-question: $NS
spec:
  storageClassName: manual-q114-05
  accessModes: ["ReadWriteOnce"]
  volumeName: q114-05-pv
  resources:
    requests:
      storage: 1Gi
---
apiVersion: v1
kind: Pod
metadata:
  name: reader
  labels:
    clusterdrill-question: $NS
spec:
  volumes:
    - name: data
      persistentVolumeClaim:
        claimName: rhine-new
  containers:
    - name: reader
      image: busybox:1.36
      command: ["sh", "-c", "cat /data/msg; sleep 3600"]
      volumeMounts:
        - name: data
          mountPath: /data
EOF

kubectl wait --for=condition=Ready pod/reader -n "$NS" --timeout=60s
sleep 2
kubectl logs reader -n "$NS"   # precious data
```

Manually created PVs default to `Retain`: the data and the PV survive when the claim is deleted,
but an admin has to clear `claimRef` deliberately before anything new can bind. Dynamically
provisioned PVs usually default to `Delete` instead, which is why q114-16 changes the policy
first, before the claim goes.
