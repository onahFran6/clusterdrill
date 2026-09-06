# q105-05: reference solution

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/

```sh
kubectl create secret docker-registry regcred \
  --docker-server=registry.example.internal \
  --docker-username=svc-deploy \
  --docker-password=hunter2-registry \
  --docker-email=svc-deploy@example.internal \
  -n q105-05-secret-docker-registry-imagepullsecret

kubectl delete pod private-app -n q105-05-secret-docker-registry-imagepullsecret

kubectl apply -n q105-05-secret-docker-registry-imagepullsecret -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: private-app
  labels:
    app: private-app
spec:
  imagePullSecrets:
    - name: regcred
  containers:
    - name: private-app
      image: nginx:1.25-alpine
EOF

kubectl wait --for=condition=Ready pod/private-app -n q105-05-secret-docker-registry-imagepullsecret --timeout=60s
```
