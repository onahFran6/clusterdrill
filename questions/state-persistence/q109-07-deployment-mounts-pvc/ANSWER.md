# q109-07: reference solution

Doc: https://kubernetes.io/docs/concepts/storage/persistent-volumes/#claims-as-volumes

```sh
NS=q109-07-deployment-mounts-pvc

kubectl apply -n "$NS" -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: uploads-api
  labels:
    clusterdrill-question: $NS
spec:
  replicas: 1
  selector:
    matchLabels:
      app: uploads-api
  template:
    metadata:
      labels:
        app: uploads-api
        clusterdrill-question: $NS
    spec:
      containers:
        - name: api
          image: nginx:1.25-alpine
          volumeMounts:
            - name: uploads-storage
              mountPath: /usr/share/nginx/html/uploads
      volumes:
        - name: uploads-storage
          persistentVolumeClaim:
            claimName: uploads-pvc
EOF

kubectl wait --for=condition=Available deployment/uploads-api -n "$NS" --timeout=60s
```
