# q102-41: reference solution

Doc: https://kubernetes.io/docs/concepts/storage/volumes/#projected

```sh
kubectl delete pod combined-config-app -n q102-41-projected-volume-merge-missing-key --ignore-not-found --wait=true

kubectl apply -n q102-41-projected-volume-merge-missing-key -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: combined-config-app
  labels:
    clusterdrill-question: q102-41-projected-volume-merge-missing-key
spec:
  containers:
    - name: app
      image: busybox:1.36
      command: ["sh", "-c", "while true; do sleep 3600; done"]
      volumeMounts:
        - name: combined
          mountPath: /etc/combined
          readOnly: true
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
    - name: sidecar-auditor
      image: busybox:1.36
      command: ["sh", "-c", "while true; do sleep 3600; done"]
      volumeMounts:
        - name: combined
          mountPath: /etc/combined
          readOnly: true
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
  volumes:
    - name: combined
      projected:
        sources:
          - configMap:
              name: app-config
              items:
                - key: app.conf
                  path: app.conf
          - secret:
              name: app-secret
              items:
                - key: api-key
                  path: api-key
                - key: db-pass
                  path: db-pass
EOF
```
