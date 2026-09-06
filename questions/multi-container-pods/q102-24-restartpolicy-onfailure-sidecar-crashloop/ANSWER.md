# q102-24: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/pods/sidecar-containers/

```sh
kubectl delete pod stream-proc -n q102-24-restartpolicy-onfailure-sidecar-crashloop --ignore-not-found --wait=true

kubectl apply -n q102-24-restartpolicy-onfailure-sidecar-crashloop -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: stream-proc
  labels:
    clusterdrill-question: q102-24-restartpolicy-onfailure-sidecar-crashloop
spec:
  restartPolicy: OnFailure
  initContainers:
    - name: log-tailer
      image: busybox:1.36
      restartPolicy: Always
      command: ["sh", "-c", "touch /data/app.log; tail -F /data/app.log"]
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
      volumeMounts:
        - name: shared-data
          mountPath: /data
  containers:
    - name: worker
      image: busybox:1.36
      command:
        - sh
        - -c
        - |
          i=0
          while true; do
            i=\$((i+1))
            echo "batch \$i processed" >> /data/app.log
            sleep 10
          done
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
      volumeMounts:
        - name: shared-data
          mountPath: /data
  volumes:
    - name: shared-data
      emptyDir: {}
EOF
```
