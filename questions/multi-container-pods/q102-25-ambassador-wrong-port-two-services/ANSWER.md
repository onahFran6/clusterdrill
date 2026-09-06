# q102-25-ambassador-wrong-port-two-services: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/pods/#how-pods-manage-multiple-containers

```sh
kubectl delete pod catalog-gateway -n q102-25-ambassador-wrong-port-two-services --ignore-not-found --wait=true

kubectl apply -n q102-25-ambassador-wrong-port-two-services -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: catalog-gateway
  labels:
    clusterdrill-question: q102-25-ambassador-wrong-port-two-services
spec:
  containers:
    - name: client
      image: busybox:1.36
      command: ["sh", "-c", "while true; do wget -q -T 2 -O - http://localhost:9090 || true; sleep 5; done"]
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
    - name: proxy
      image: alpine:3.20
      command: ["sh", "-c", "apk add --no-cache socat && socat TCP-LISTEN:9090,fork,reuseaddr TCP:catalog-primary:8080"]
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
EOF
```
