# q108-09: reference solution

Doc: https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/

```sh
RESOLVED_IP=$(kubectl exec netshoot -n q108-09-dns-resolve-cross-namespace -- \
  sh -c "nslookup kubernetes.default.svc.cluster.local" | awk '/^Address/{print $2}' | tail -1)

kubectl create configmap cross-ns-lookup-result \
  -n q108-09-dns-resolve-cross-namespace \
  --from-literal=service-ip="$RESOLVED_IP"
```
