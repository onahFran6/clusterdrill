# q101-24-fix-secret-mount-wrong-key-path: reference solution

Doc: https://kubernetes.io/docs/concepts/configuration/secret/#using-secrets-as-files-from-a-pod

```sh
NS=q101-24-fix-secret-mount-wrong-key-path

# 1. Diagnose: describe shows a FailedMount event referencing a Secret key
# that doesn't exist ("secret \"tls-creds\" has no key \"cert.pem\"").
kubectl describe pod cert-server -n "$NS" | grep -A5 Events

# 2. The items key list can't be changed on a running pod's volume spec
# in place, so dump the existing pod's manifest, fix the one wrong field
# (items[].key: cert.pem -> tls.crt), strip the fields the apiserver
# rejects on create, then delete and recreate imperatively.
kubectl get pod cert-server -n "$NS" -o yaml \
  | sed 's/key: cert\.pem/key: tls.crt/' \
  > /tmp/cert-server-fixed.yaml

kubectl delete pod cert-server -n "$NS" --ignore-not-found --wait=true

kubectl apply -f /tmp/cert-server-fixed.yaml

kubectl wait --for=condition=Ready pod/cert-server -n "$NS" --timeout=60s

kubectl exec cert-server -n "$NS" -- cat /etc/certs/cert.pem
```
