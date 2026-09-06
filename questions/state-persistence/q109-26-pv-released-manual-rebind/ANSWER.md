# q109-26-pv-released-manual-rebind: reference solution

Doc: https://kubernetes.io/docs/concepts/storage/persistent-volumes/#reclaiming

```sh
QUESTION_ID="q109-26-pv-released-manual-rebind"

kubectl patch pv legacy-pv --type=json \
  -p '[{"op":"remove","path":"/spec/claimRef"}]'

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: recovered-claim
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: ""
  resources:
    requests:
      storage: 80Mi
EOF

kubectl wait --for=jsonpath='{.status.phase}'=Bound pvc/recovered-claim -n "$QUESTION_ID" --timeout=60s
```
