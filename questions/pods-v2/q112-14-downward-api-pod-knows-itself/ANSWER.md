# q112-14: reference solution

Doc: https://kubernetes.io/docs/tasks/inject-data-application/downward-api-volume-expose-pod-information/

```sh
NS=q112-14-downward-api-pod-knows-itself

cat <<EOF | kubectl apply -n "$NS" -f -
apiVersion: v1
kind: Pod
metadata:
  name: meta
  labels:
    app: meta
    version: v3
    clusterdrill-question: $NS
  annotations:
    build: "4521"
spec:
  volumes:
    - name: podinfo
      downwardAPI:
        items:
          - path: labels
            fieldRef:
              fieldPath: metadata.labels
          - path: annotations
            fieldRef:
              fieldPath: metadata.annotations
  containers:
    - name: agent
      image: busybox:1.36
      command: ["sleep", "3600"]
      resources:
        limits:
          memory: 64Mi
      env:
        - name: POD_IP
          valueFrom:
            fieldRef:
              fieldPath: status.podIP
        - name: MEM_LIMIT_MI
          valueFrom:
            resourceFieldRef:
              containerName: agent
              resource: limits.memory
              divisor: 1Mi
      volumeMounts:
        - name: podinfo
          mountPath: /etc/podinfo
EOF

kubectl wait --for=condition=Ready pod/meta -n "$NS" --timeout=60s
kubectl exec meta -n "$NS" -- printenv MEM_LIMIT_MI
kubectl exec meta -n "$NS" -- cat /etc/podinfo/labels
```

Annotation values must be strings, so `build: "4521"` needs the quotes or the API rejects the
Pod outright. A downward API volume's label/annotation files update in place whenever the
Pod's labels or annotations change later; env vars like `POD_IP` and `MEM_LIMIT_MI` are captured
once at container start and never do.
