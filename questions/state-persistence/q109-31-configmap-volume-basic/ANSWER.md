# q109-31-configmap-volume-basic: reference solution

Doc: https://kubernetes.io/docs/concepts/configuration/configmap/#configmaps-and-pods

```sh
kubectl apply -n q109-31-configmap-volume-basic -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: settings-reader
spec:
  containers:
    - name: settings-reader
      image: busybox:1.36
      command: ["sh", "-c", "sleep 3600"]
      volumeMounts:
        - name: settings
          mountPath: /etc/app-settings
  volumes:
    - name: settings
      configMap:
        name: app-settings
EOF

kubectl wait --for=condition=Ready pod/settings-reader -n q109-31-configmap-volume-basic --timeout=60s
```
