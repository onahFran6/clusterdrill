# q105-18: reference solution

Doc: https://kubernetes.io/docs/concepts/configuration/secret/#secret-files-permissions

```sh
kubectl delete pod deploy-agent -n q105-18-secret-volume-default-mode

kubectl apply -n q105-18-secret-volume-default-mode -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: deploy-agent
  labels:
    app: deploy-agent
spec:
  containers:
    - name: deploy-agent
      image: nginx:1.25-alpine
      volumeMounts:
        - name: ssh-key
          mountPath: /etc/ssh-key
  volumes:
    - name: ssh-key
      secret:
        secretName: ssh-key
        defaultMode: 0400
EOF

kubectl wait --for=condition=Ready pod/deploy-agent -n q105-18-secret-volume-default-mode --timeout=60s
```
