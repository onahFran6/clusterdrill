# q109-19: reference solution

Doc: https://kubernetes.io/docs/concepts/storage/projected-volumes/

```sh
kubectl apply -n q109-19-projected-volume-secret-downwardapi -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: combo-app
spec:
  containers:
    - name: combo-app
      image: busybox:1.36
      command: ["sleep", "3600"]
      volumeMounts:
        - name: combo
          mountPath: /etc/combo
  volumes:
    - name: combo
      projected:
        sources:
          - secret:
              name: api-creds
              items:
                - key: token
                  path: secret-token
          - downwardAPI:
              items:
                - path: pod-name
                  fieldRef:
                    fieldPath: metadata.name
EOF

kubectl wait --for=condition=Ready pod/combo-app \
  -n q109-19-projected-volume-secret-downwardapi --timeout=60s
```
