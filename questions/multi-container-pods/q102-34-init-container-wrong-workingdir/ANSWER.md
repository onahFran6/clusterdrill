# q102-34: reference solution

Doc: https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#Container

```sh
kubectl delete pod handoff-app -n q102-34-init-container-wrong-workingdir --ignore-not-found --wait=true

kubectl apply -n q102-34-init-container-wrong-workingdir -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: handoff-app
  labels:
    clusterdrill-question: q102-34-init-container-wrong-workingdir
spec:
  initContainers:
    - name: stager
      image: busybox:1.36
      command: ["sh", "-c", "echo shipment-ready-778 > handoff.txt"]
      workingDir: /stage
      volumeMounts:
        - name: stage-data
          mountPath: /stage
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
  containers:
    - name: consumer
      image: busybox:1.36
      command: ["sh", "-c", "while true; do sleep 3600; done"]
      volumeMounts:
        - name: stage-data
          mountPath: /consume
      resources:
        requests:
          cpu: 25m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 64Mi
  volumes:
    - name: stage-data
      emptyDir: {}
EOF
```
