# q105-36-secret-basicauth-stringdata: reference solution

Doc: https://kubernetes.io/docs/concepts/configuration/secret/#basic-authentication-secret

```sh
kubectl apply -n q105-36-secret-basicauth-stringdata -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: proxy-creds
  labels:
    clusterdrill-question: q105-36-secret-basicauth-stringdata
type: kubernetes.io/basic-auth
stringData:
  username: svc-proxy
  password: Tr0ub4dor&3
EOF

kubectl delete pod auth-proxy -n q105-36-secret-basicauth-stringdata

kubectl apply -n q105-36-secret-basicauth-stringdata -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: auth-proxy
  labels:
    app: auth-proxy
spec:
  containers:
    - name: auth-proxy
      image: nginx:1.25-alpine
      env:
        - name: AUTH_USER
          valueFrom:
            secretKeyRef:
              name: proxy-creds
              key: username
        - name: AUTH_PASS
          valueFrom:
            secretKeyRef:
              name: proxy-creds
              key: password
EOF

kubectl wait --for=condition=Ready pod/auth-proxy -n q105-36-secret-basicauth-stringdata --timeout=60s
```
