# q109-23: reference solution

Doc: https://kubernetes.io/docs/concepts/storage/ephemeral-volumes/#generic-ephemeral-volumes

```sh
NS=q109-23-generic-ephemeral-volume

kubectl apply -n "$NS" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: ephemeral-app
  labels:
    clusterdrill-question: $NS
spec:
  containers:
    - name: ephemeral-app
      image: busybox:1.36
      command: ["sh", "-c", "sleep 3600"]
      volumeMounts:
        - name: scratch
          mountPath: /scratch
  volumes:
    - name: scratch
      ephemeral:
        volumeClaimTemplate:
          spec:
            accessModes: ["ReadWriteOnce"]
            resources:
              requests:
                storage: 50Mi
EOF

kubectl wait --for=condition=Ready pod/ephemeral-app -n "$NS" --timeout=60s
kubectl wait --for=jsonpath='{.status.phase}'=Bound pvc/ephemeral-app-scratch -n "$NS" --timeout=60s
```
