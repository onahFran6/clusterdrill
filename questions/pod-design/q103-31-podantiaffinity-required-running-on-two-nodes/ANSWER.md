# q103-31: reference solution

Doc: https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#affinity-and-anti-affinity

```sh
QUESTION_ID="q103-31-podantiaffinity-required-running-on-two-nodes"

# .spec.affinity is immutable on an existing pod - cache-1 must be deleted
# and recreated to add the required anti-affinity rule. cache-0 is left
# alone.
kubectl delete pod cache-1 -n "$QUESTION_ID" --wait=true

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: cache-1
  labels:
    app: cache-replica
    clusterdrill-question: $QUESTION_ID
spec:
  affinity:
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        - labelSelector:
            matchLabels:
              app: cache-replica
          topologyKey: kubernetes.io/hostname
  containers:
    - name: cache
      image: busybox:1.36
      command: ["sleep", "3600"]
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
EOF

kubectl wait --for=condition=Ready pod/cache-1 -n "$QUESTION_ID" --timeout=60s
kubectl get pod cache-0 cache-1 -n "$QUESTION_ID" -o wide
```
