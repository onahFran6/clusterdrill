# q114-04: reference solution

Doc: https://kubernetes.io/docs/concepts/storage/persistent-volumes/#reserving-a-persistentvolume

```sh
NS=q114-04-reserve-for-a-future-claim

kubectl patch pv q114-04-a -p '{"spec":{"claimRef":{"namespace":"'"$NS"'","name":"reserved"}}}'

claim() {
  cat <<EOF | kubectl apply -n "$NS" -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: $1
  labels:
    clusterdrill-question: $NS
spec:
  storageClassName: manual-q114-04
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 1Gi
  $2
EOF
}

claim volga-claim "volumeName: q114-04-b"
kubectl wait --for=jsonpath='{.status.phase}'=Bound pvc/volga-claim -n "$NS" --timeout=60s

claim other ""
claim reserved ""
kubectl wait --for=jsonpath='{.status.phase}'=Bound pvc/reserved -n "$NS" --timeout=60s
```

`volumeName` on the claim and `claimRef` on the PV together give a guaranteed one-to-one pairing.
`other` stays `Pending` forever because the class has no provisioner and both real PVs are already
spoken for; `reserved` binds to `q114-04-a` the moment it's created, because the PV was already
holding the door open for exactly that name.
