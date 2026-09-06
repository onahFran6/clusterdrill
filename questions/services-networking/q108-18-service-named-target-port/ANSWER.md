# q108-18: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/service/#defining-a-service

```sh
kubectl apply -n q108-18-service-named-target-port -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: image-resizer-svc
spec:
  type: ClusterIP
  selector:
    app: image-resizer
  ports:
    - port: 80
      targetPort: worker-port
EOF
```
