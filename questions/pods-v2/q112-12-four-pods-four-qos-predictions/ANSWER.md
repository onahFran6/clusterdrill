# q112-12: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/pods/pod-qos/

```sh
NS=q112-12-four-pods-four-qos-predictions

cat <<EOF | kubectl apply -n "$NS" -f -
apiVersion: v1
kind: Pod
metadata:
  name: gold
  labels:
    clusterdrill-question: $NS
spec:
  containers:
    - name: app
      image: nginx:1.27
      resources:
        requests: { cpu: 100m, memory: 64Mi }
        limits: { cpu: 100m, memory: 64Mi }
---
apiVersion: v1
kind: Pod
metadata:
  name: silver
  labels:
    clusterdrill-question: $NS
spec:
  containers:
    - name: app
      image: nginx:1.27
      resources:
        requests: { cpu: 50m }
---
apiVersion: v1
kind: Pod
metadata:
  name: bronze
  labels:
    clusterdrill-question: $NS
spec:
  containers:
    - name: app
      image: nginx:1.27
---
apiVersion: v1
kind: Pod
metadata:
  name: tin
  labels:
    clusterdrill-question: $NS
spec:
  containers:
    - name: app
      image: nginx:1.27
      resources:
        limits: { cpu: 100m, memory: 64Mi }
EOF

kubectl wait --for=condition=Ready pod/gold pod/silver pod/bronze pod/tin -n "$NS" --timeout=60s
kubectl get pods -n "$NS" -o custom-columns=NAME:.metadata.name,QOS:.status.qosClass
```

`tin` lands in `Guaranteed`, the same class as `gold`, because the API server backfills a missing
`requests` with the container's own `limits` whenever a limit is set - `tin`'s *declared* spec
only ever has a `limits` block, but admission makes its effective `requests` equal to it, which is
exactly what `Guaranteed` requires. `kubectl run` no longer accepts resource flags, so each Pod
here has to be written out as YAML.
