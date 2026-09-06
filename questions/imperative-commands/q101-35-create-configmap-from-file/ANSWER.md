# q101-35-create-configmap-from-file: reference solution

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/#create-a-configmap-from-a-file

```sh
kubectl create configmap app-props \
  -n q101-35-create-configmap-from-file \
  --from-file="$HOME/practice-work/q101-35-create-configmap-from-file/app.properties"
```
