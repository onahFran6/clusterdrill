# q102-33: reference solution

Doc: https://kubernetes.io/docs/concepts/configuration/configmap/#configmaps-and-pods

```sh
kubectl apply -n q102-33-two-container-configmap-volume-two-mounts -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: settings-readers
  labels:
    clusterdrill-question: q102-33-two-container-configmap-volume-two-mounts
spec:
  containers:
    - name: primary
      image: busybox:1.36
      command: ["sh", "-c", "while true; do sleep 3600; done"]
      volumeMounts:
        - name: settings
          mountPath: /etc/primary-settings
    - name: secondary
      image: busybox:1.36
      command: ["sh", "-c", "while true; do sleep 3600; done"]
      volumeMounts:
        - name: settings
          mountPath: /etc/secondary-settings
  volumes:
    - name: settings
      configMap:
        name: shared-settings
EOF
```
