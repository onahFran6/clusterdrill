# q105-30-projected-volume-configmap-and-secret: reference solution

Doc: https://kubernetes.io/docs/concepts/storage/projected-volumes/

```sh
kubectl delete pod combiner -n q105-30-projected-volume-configmap-and-secret --ignore-not-found

kubectl apply -n q105-30-projected-volume-configmap-and-secret -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: combiner
  labels:
    app: combiner
    clusterdrill-question: q105-30-projected-volume-configmap-and-secret
spec:
  containers:
    - name: combiner
      image: busybox:1.36
      command: ["sh", "-c", "sleep 3600"]
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
      volumeMounts:
        - name: combined
          mountPath: /etc/combined
  volumes:
    - name: combined
      projected:
        sources:
          - configMap:
              name: app-settings
          - secret:
              name: app-secret-key
EOF

kubectl wait --for=condition=Ready pod/combiner -n q105-30-projected-volume-configmap-and-secret --timeout=60s
```
