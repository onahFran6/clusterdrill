# q102-04: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/pods/#how-pods-manage-multiple-containers

```sh
kubectl delete pod app -n q102-04-adapter-log-format-normalizer --ignore-not-found --wait=true

kubectl apply -n q102-04-adapter-log-format-normalizer -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: app
  labels:
    clusterdrill-question: q102-04-adapter-log-format-normalizer
spec:
  containers:
    - name: producer
      image: busybox:1.36
      command: ["sh", "-c", "while true; do echo 'LEVEL=info MSG=hello' >> /data/raw.log; sleep 5; done"]
      volumeMounts:
        - name: shared-data
          mountPath: /data
    - name: adapter
      image: busybox:1.36
      command:
        - "sh"
        - "-c"
        - |
          touch /data/raw.log
          while true; do
            LINE=$(tail -n 1 /data/raw.log)
            LEVEL=$(echo "$LINE" | sed -n 's/.*LEVEL=\([^ ]*\).*/\1/p')
            MSG=$(echo "$LINE" | sed -n 's/.*MSG=\([^ ]*\).*/\1/p')
            if [ -n "$LEVEL" ] || [ -n "$MSG" ]; then
              echo "{\"level\":\"$LEVEL\",\"msg\":\"$MSG\"}" >> /data/normalized.log
            fi
            sleep 5
          done
      volumeMounts:
        - name: shared-data
          mountPath: /data
  volumes:
    - name: shared-data
      emptyDir: {}
EOF
```
