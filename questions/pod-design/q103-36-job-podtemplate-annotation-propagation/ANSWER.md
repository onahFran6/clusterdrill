# q103-36: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/controllers/job/#pod-template

```sh
NS=q103-36-job-podtemplate-annotation-propagation

kubectl delete job metadata-tagger -n "$NS" --wait=true

kubectl apply -n "$NS" -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: metadata-tagger
  labels:
    clusterdrill-question: $NS
spec:
  template:
    metadata:
      labels:
        clusterdrill-question: $NS
      annotations:
        pipeline.example.com/build-id: "2026-09"
    spec:
      restartPolicy: Never
      containers:
        - name: metadata-tagger
          image: busybox:1.36
          command: ["echo", "tagged"]
          resources:
            requests:
              cpu: 25m
              memory: 32Mi
            limits:
              cpu: 50m
              memory: 64Mi
EOF

kubectl wait --for=condition=Complete job/metadata-tagger -n "$NS" --timeout=60s
```
