# q108-37-fix-nodeport-out-of-range: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/service/#type-nodeport

```sh
kubectl apply -n q108-37-fix-nodeport-out-of-range -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: billing-svc
spec:
  type: NodePort
  selector:
    app: billing
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30090
EOF
```
