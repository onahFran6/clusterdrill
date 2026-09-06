# q108-01: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/service/#type-nodeport

```sh
kubectl apply -n q108-01-nodeport-fixed-port -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: metrics-agent-svc
spec:
  type: NodePort
  selector:
    app: metrics-agent
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30080
EOF
```
