# q114-08: reference solution

Doc: https://kubernetes.io/docs/concepts/storage/persistent-volumes/#expanding-persistent-volumes-claims

```sh
NS=q114-08-can-this-claim-grow
DEFAULT_SC="$(kubectl get sc -o jsonpath='{range .items[?(@.metadata.annotations.storageclass\.kubernetes\.io/is-default-class=="true")]}{.metadata.name}{end}')"

kubectl patch pvc tiber-data -n "$NS" -p '{"spec":{"resources":{"requests":{"storage":"500Mi"}}}}' || true
# ... field is immutable except resources.requests for storage; only a dynamically provisioned
# PVC whose StorageClass itself allows expansion can ever grow.
kubectl get sc "$DEFAULT_SC" -o jsonpath='{.allowVolumeExpansion}'; echo   # empty = false

kubectl apply -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: q114-08-expandable
  labels:
    clusterdrill-question: $NS
provisioner: $(kubectl get sc "$DEFAULT_SC" -o jsonpath='{.provisioner}')
allowVolumeExpansion: true
EOF

kubectl apply -n "$NS" -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: q114-08-new-data
  labels:
    clusterdrill-question: $NS
spec:
  storageClassName: q114-08-expandable
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 200Mi
EOF

kubectl wait --for=jsonpath='{.status.phase}'=Bound pvc/q114-08-new-data -n "$NS" --timeout=60s || true
kubectl patch pvc q114-08-new-data -n "$NS" -p '{"spec":{"resources":{"requests":{"storage":"500Mi"}}}}'
```

A claim's class is fixed at creation, so creating a new expandable class only ever helps **new**
claims - `tiber-data` itself can never move to it. Even with `allowVolumeExpansion: true`, whether
the request physically grows the volume depends on the provisioner's own `ControllerExpandVolume`
support, which varies by cluster - this is why grading only ever looks at the requested
`spec.resources.requests.storage`, never `status.capacity`. Claims can never shrink.
