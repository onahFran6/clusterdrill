# q102-18: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/pods/#how-pods-manage-multiple-containers

```sh
kubectl apply -n q102-18-three-way-pipeline-volume -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: pipeline-app
  labels:
    clusterdrill-question: q102-18-three-way-pipeline-volume
spec:
  containers:
    - name: generator
      image: busybox:1.36
      command: ["sh", "-c", "i=0; while true; do echo \$i >> /pipeline/stage1.txt; i=\$((i+1)); sleep 5; done"]
      volumeMounts:
        - name: pipeline-data
          mountPath: /pipeline
    - name: processor
      image: busybox:1.36
      command: ["sh", "-c", "while true; do if [ -f /pipeline/stage1.txt ]; then awk '{print \$1*2}' /pipeline/stage1.txt >> /pipeline/stage2.txt; fi; sleep 5; done"]
      volumeMounts:
        - name: pipeline-data
          mountPath: /pipeline
    - name: consumer
      image: busybox:1.36
      command: ["sh", "-c", "sleep 5; tail -f /pipeline/stage2.txt"]
      volumeMounts:
        - name: pipeline-data
          mountPath: /pipeline
  volumes:
    - name: pipeline-data
      emptyDir: {}
EOF
```
