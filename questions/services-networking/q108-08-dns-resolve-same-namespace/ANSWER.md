# q108-08: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/

```sh
RESOLVED_IP=$(kubectl exec netshoot -n q108-08-dns-resolve-same-namespace -- \
  sh -c "nslookup inventory-svc" | awk '/^Address/{print $2}' | tail -1)

kubectl create configmap dns-lookup-result \
  -n q108-08-dns-resolve-same-namespace \
  --from-literal=service-ip="$RESOLVED_IP"
```
