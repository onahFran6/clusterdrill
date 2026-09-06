# q102-29: reference solution

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/assign-memory-resource/

```sh
QUESTION_ID="q102-29-limitrange-rebalance-prevent-sidecar-oomkill"

# Resources on a container are immutable once the Pod exists - delete and
# recreate with the rebalanced values.
kubectl delete pod batch-processor -n "$QUESTION_ID" --ignore-not-found --wait=true

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: batch-processor
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  containers:
    - name: main
      image: busybox:1.36
      command:
        - awk
        - BEGIN{s=sprintf("%-90000000s",""); print length(s); system("sleep 3600")}
      resources:
        requests:
          cpu: 25m
          memory: 96Mi
        limits:
          cpu: 100m
          memory: 120Mi
    - name: metrics-sidecar
      image: busybox:1.36
      command: ["sh", "-c", "while true; do echo heartbeat >> /tmp/metrics.log; sleep 15; done"]
      resources:
        requests:
          cpu: 25m
          memory: 16Mi
        limits:
          cpu: 50m
          memory: 32Mi
EOF

kubectl wait --for=jsonpath='{.status.phase}'=Running \
  pod/batch-processor -n "$QUESTION_ID" --timeout=90s
```

`main`'s memory limit went from `24Mi` (far below the ~86Mi buffer it
actually builds, so the kubelet OOMKilled it on every attempt) to `120Mi` -
comfortable headroom under the namespace `LimitRange`'s `128Mi`
per-container ceiling. `metrics-sidecar`'s limit went from a wasteful
`112Mi` down to `32Mi`, which is still generous for a container that only
ever appends one short heartbeat line every 15 seconds. Both containers'
own `resources` stay entirely within the unmodified `container-mem-ceiling`
`LimitRange`.
