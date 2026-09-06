# q108-02: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/service/#multi-port-services

```sh
kubectl apply -n q108-02-multiport-service -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: web-app-svc
spec:
  type: ClusterIP
  selector:
    app: web-app
  ports:
    - name: http
      port: 80
      targetPort: 80
    - name: https
      port: 443
      targetPort: 8443
EOF
```
