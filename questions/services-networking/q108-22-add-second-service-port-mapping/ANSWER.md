# q108-22-add-second-service-port-mapping: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/service/#multi-port-services

```sh
kubectl apply -n q108-22-add-second-service-port-mapping -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: metrics-agent-svc
spec:
  selector:
    app: metrics-agent
  ports:
    - name: http
      port: 8080
      targetPort: 8080
    - name: metrics
      port: 9090
      targetPort: 9090
EOF
```
