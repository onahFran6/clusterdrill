# q103-47: reference solution

Doc: https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/

**Approach A - Fastest (exam default).** Rewrite the whole file from a known-good manifest -
for two sibling affinity blocks nested 3-4 levels deep, that's lower error risk than
hand-splicing indentation into the existing file:

```sh
NS=q103-47-combined-nodeaffinity-podantiaffinity-manifest
MANIFEST="$HOME/practice-work/$NS/constrained-worker.yaml"

cat > "$MANIFEST" <<YAML
apiVersion: v1
kind: Pod
metadata:
  name: constrained-worker
  namespace: $NS
  labels:
    clusterdrill-question: $NS
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
          - matchExpressions:
              - key: kubernetes.io/os
                operator: In
                values:
                  - linux
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        - labelSelector:
            matchLabels:
              app: legacy-worker
          topologyKey: kubernetes.io/hostname
  containers:
    - name: constrained-worker
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

kubectl wait --for=condition=Ready pod/constrained-worker -n "$NS" --timeout=60s
```

**Approach B - Alternative.** Edit the existing file in place in vim - faster if you're confident
navigating a two-block insert without losing track of indentation:

```text
vim ~/practice-work/q103-47-combined-nodeaffinity-podantiaffinity-manifest/constrained-worker.yaml
/spec:<Enter>
o  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
          - matchExpressions:
              - key: kubernetes.io/os
                operator: In
                values:
                  - linux
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        - labelSelector:
            matchLabels:
              app: legacy-worker
          topologyKey: kubernetes.io/hostname
<Esc>
:wq
```

| Method | Typing | Error risk | Reusable |
|---|---|---|---|
| A - rewrite whole file | medium (paste) | low - structure is correct by construction | high - same pattern for any deeply-nested block |
| B - vim in-place edit | low (only the new block) | medium - two sibling blocks, easy to misindent one | high - the general "edit existing file" reflex |
