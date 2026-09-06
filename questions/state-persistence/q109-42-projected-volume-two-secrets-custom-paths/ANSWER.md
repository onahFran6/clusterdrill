# q109-42-projected-volume-two-secrets-custom-paths: reference solution

Doc: https://kubernetes.io/docs/concepts/storage/projected-volumes/

```sh
kubectl apply -n q109-42-projected-volume-two-secrets-custom-paths -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: multi-secret-reader
spec:
  containers:
    - name: multi-secret-reader
      image: busybox:1.36
      command: ["sh", "-c", "sleep 3600"]
      volumeMounts:
        - name: creds
          mountPath: /etc/creds
  volumes:
    - name: creds
      projected:
        sources:
          - secret:
              name: db-credentials
              items:
                - key: password
                  path: db/password
          - secret:
              name: api-credentials
              items:
                - key: token
                  path: api/token
EOF

kubectl wait --for=condition=Ready pod/multi-secret-reader -n q109-42-projected-volume-two-secrets-custom-paths --timeout=60s
```
