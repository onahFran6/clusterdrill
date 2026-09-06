# q105-22: reference solution

Doc: https://kubernetes.io/docs/concepts/configuration/secret/#ssh-authentication-secrets

```sh
kubectl create secret generic deploy-key \
  --type=kubernetes.io/ssh-auth \
  --from-file=ssh-privatekey=$HOME/practice-work/q105-22-secret-ssh-auth-type/id_rsa \
  -n q105-22-secret-ssh-auth-type

kubectl delete pod deploy-agent -n q105-22-secret-ssh-auth-type

kubectl apply -n q105-22-secret-ssh-auth-type -f - <<EOF
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
        secretName: deploy-key
EOF

kubectl wait --for=condition=Ready pod/deploy-agent -n q105-22-secret-ssh-auth-type --timeout=60s
```
