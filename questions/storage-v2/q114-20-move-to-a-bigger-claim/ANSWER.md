# q114-20: reference solution

Doc: https://kubernetes.io/docs/concepts/storage/persistent-volumes/#expanding-persistent-volumes-claims

```sh
NS=q114-20-move-to-a-bigger-claim

kubectl apply -n "$NS" -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: new-data
  labels:
    clusterdrill-question: $NS
spec:
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 500Mi
EOF

kubectl scale deployment archive -n "$NS" --replicas=0
kubectl wait --for=delete pod -l app=archive -n "$NS" --timeout=60s

kubectl run mover -n "$NS" --image=busybox:1.36 --restart=Never \
  --overrides='{"spec":{"volumes":[{"name":"o","persistentVolumeClaim":{"claimName":"old-data"}},{"name":"n","persistentVolumeClaim":{"claimName":"new-data"}}],"containers":[{"name":"m","image":"busybox:1.36","command":["sh","-c","cp -a /old/. /new/ && ls /new"],"volumeMounts":[{"name":"o","mountPath":"/old"},{"name":"n","mountPath":"/new"}]}]}}'
kubectl wait --for=jsonpath='{.status.phase}'=Succeeded pod/mover -n "$NS" --timeout=60s
kubectl logs mover -n "$NS"
kubectl delete pod mover -n "$NS"

kubectl patch deployment archive -n "$NS" --type=json \
  -p='[{"op":"replace","path":"/spec/template/spec/volumes/0/persistentVolumeClaim/claimName","value":"new-data"}]'
kubectl scale deployment archive -n "$NS" --replicas=1
kubectl rollout status deployment/archive -n "$NS" --timeout=60s
kubectl exec deploy/archive -n "$NS" -- ls /archive
```

`/old/.` copies hidden files too. The app's own single-shot startup command rewrites `r1`-`r3` on
any empty claim regardless of whether `mover` actually copied anything first - the real lesson
here is the migration *workflow* (stop the writer, copy while idle, repoint, resume), not a
forensic proof of data provenance. Keep `old-data` around until the new one is verified, and
consider setting its PV's reclaim policy to `Retain` first, as in q114-16.
