# q114-03: reference solution

Doc: https://kubernetes.io/docs/concepts/storage/persistent-volumes/#binding

```sh
NS=q114-03-which-size-wins

kubectl apply -n "$NS" -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: danube-claim
  labels:
    clusterdrill-question: $NS
spec:
  storageClassName: manual-q114-03
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 2Gi
EOF

kubectl wait --for=jsonpath='{.status.phase}'=Bound pvc/danube-claim -n "$NS" --timeout=60s
```

The controller picks the **smallest** PV that satisfies the request (`q114-03-5g`, not the
10Gi one), and the claim gets all of it. `spec.resources.requests` keeps reading `2Gi`, while
`status.capacity` reports the PV's actual `5Gi`.
