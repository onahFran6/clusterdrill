# q102-30: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/pods/sidecar-containers/

```sh
QUESTION_ID="q102-30-job-native-sidecar-completion-semantics"

# The Job's spec.template is immutable once created, so the broken Job must
# be deleted and recreated with log-shipper wired up as a native sidecar
# (initContainers entry, restartPolicy: Always) instead of a regular
# container.
kubectl delete job log-shipping-job -n "$QUESTION_ID" --wait=true

kubectl apply -n "$QUESTION_ID" -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: log-shipping-job
  labels:
    clusterdrill-question: $QUESTION_ID
spec:
  backoffLimit: 0
  template:
    metadata:
      labels:
        clusterdrill-question: $QUESTION_ID
    spec:
      restartPolicy: Never
      initContainers:
        - name: log-shipper
          image: busybox:1.36
          restartPolicy: Always
          command: ["sh", "-c", "while true; do echo shipping logs; sleep 5; done"]
          resources:
            requests:
              cpu: 25m
              memory: 32Mi
            limits:
              cpu: 50m
              memory: 64Mi
      containers:
        - name: digest
          image: busybox:1.36
          command: ["sh", "-c", "echo processing batch; sleep 5; exit 0"]
          resources:
            requests:
              cpu: 25m
              memory: 32Mi
            limits:
              cpu: 50m
              memory: 64Mi
EOF

kubectl wait --for=condition=Complete job/log-shipping-job -n "$QUESTION_ID" --timeout=60s
```
