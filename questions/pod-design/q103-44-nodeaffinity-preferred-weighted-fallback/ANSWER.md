# q103-44: reference solution

Doc: https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#node-affinity

**Approach A - Fastest (exam default).** Rewrite the whole file from a known-good manifest -
for a 4-level-nested block like this, that's lower error risk than hand-splicing indentation
into the existing file:

```sh
NS=q103-44-nodeaffinity-preferred-weighted-fallback
MANIFEST="$HOME/practice-work/$NS/flexible-worker.yaml"

cat > "$MANIFEST" <<YAML
apiVersion: v1
kind: Pod
metadata:
  name: flexible-worker
  namespace: $NS
  labels:
    clusterdrill-question: $NS
spec:
  affinity:
    nodeAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
        - weight: 80
          preference:
            matchExpressions:
              - key: kubernetes.io/os
                operator: In
                values:
                  - linux
        - weight: 20
          preference:
            matchExpressions:
              - key: kubernetes.io/arch
                operator: In
                values:
                  - arm64
  containers:
    - name: flexible-worker
      image: busybox:1.36
      command: ["sleep", "3600"]
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
YAML

kubectl apply -f "$MANIFEST"

kubectl wait --for=condition=Ready pod/flexible-worker -n "$NS" --timeout=60s
```

**Approach B - Alternative.** Edit the existing file in place in vim - faster if you trust
yourself not to fumble the indentation on a 4-level-deep block:

```text
vim ~/practice-work/q103-44-nodeaffinity-preferred-weighted-fallback/flexible-worker.yaml
/spec:<Enter>
o  affinity:
    nodeAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
        - weight: 80
          preference:
            matchExpressions:
              - key: kubernetes.io/os
                operator: In
                values:
                  - linux
        - weight: 20
          preference:
            matchExpressions:
              - key: kubernetes.io/arch
                operator: In
                values:
                  - arm64
<Esc>
:wq
```

| Method | Typing | Error risk | Reusable |
|---|---|---|---|
| A - rewrite whole file | medium (paste) | low - structure is correct by construction | high - same pattern for any deeply-nested block |
| B - vim in-place edit | low (only the new block) | medium - manual indentation on 4 nesting levels | high - the general "edit existing file" reflex |
