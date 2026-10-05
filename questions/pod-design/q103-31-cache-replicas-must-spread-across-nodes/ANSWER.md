# q103-31: reference solution

Doc: https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#affinity-and-anti-affinity

**Approach A - Fastest (exam default).** Edit cache-1 in place so you only touch the affinity
block, not the whole pod:

```text
kubectl edit pod cache-1 -n q103-31-cache-replicas-must-spread-across-nodes
# In the editor: add a requiredDuringSchedulingIgnoredDuringExecution block
# (labelSelector app=cache-replica, topologyKey kubernetes.io/hostname),
# then :wq
# spec.affinity is immutable, so the save is rejected - kubectl saves your
# edit to a temp file and prints its path, e.g. /tmp/kubectl-edit-XXXX.yaml
kubectl replace --force -f /tmp/kubectl-edit-XXXX.yaml
```

**Approach B - Alternative.** Delete and recreate from a full manifest - safer when you'd rather
see the entire pod spec before applying than trust an auto-saved temp file. This is what's
actually executed below for automated verification:

```sh
QUESTION_ID="q103-31-cache-replicas-must-spread-across-nodes"

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

| Method | Typing | Error risk | Reusable |
|---|---|---|---|
| A - edit, rejected, replace --force | lowest (touch only the affinity block) | low (vim shows the diff) | high - the standard immutable-field-on-a-Pod reflex |
| B - delete + heredoc manifest | higher (retype the whole pod spec) | low (full spec visible before apply) | medium (this exact shape) |
