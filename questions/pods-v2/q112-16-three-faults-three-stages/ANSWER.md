# q112-16: reference solution

Doc: https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/

```sh
NS=q112-16-three-faults-three-stages

kubectl describe pod report -n "$NS" | tail -5   # persistentvolumeclaim "report-data" not found

cat <<EOF | kubectl apply -n "$NS" -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: report-data
  labels:
    clusterdrill-question: $NS
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 100Mi
EOF

kubectl get pod report -n "$NS" -w --timeout=30s 2>/dev/null | head -1   # ImagePullBackOff
kubectl set image pod/report report=busybox:1.36 -n "$NS"

kubectl get pod report -n "$NS"   # CreateContainerConfigError
kubectl get secret report-secret -n "$NS" -o jsonpath='{.data}'; echo   # real key is api-key, not apikey

kubectl replace --force -n "$NS" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: report
  labels:
    clusterdrill-question: $NS
spec:
  volumes:
    - name: data
      persistentVolumeClaim:
        claimName: report-data
  containers:
    - name: report
      image: busybox:1.36
      command: ["sleep", "3600"]
      env:
        - name: API_KEY
          valueFrom:
            secretKeyRef:
              name: report-secret
              key: api-key
      volumeMounts:
        - name: data
          mountPath: /data
EOF

kubectl wait --for=condition=Ready pod/report -n "$NS" --timeout=60s
```

| Order | Status | Stage | Cause | Fix |
|---|---|---|---|---|
| 1 | `Pending` | admission/scheduling | PVC `report-data` did not exist | Create the PVC |
| 2 | `ErrImagePull`/`ImagePullBackOff` | image-pull | tag `busybox:1.366` doesn't exist | `kubectl set image` (allowed live) |
| 3 | `CreateContainerConfigError` | container-config | Secret key `apikey`, real key is `api-key` | `kubectl replace --force` |

The kubelet pulls the image before it builds the container's env, which is why the image fault
surfaces before the Secret-key fault even though both were present from the start. A container's
`image` is one of the few fields `kubectl set image`/`kubectl edit` can change on a live Pod; the
Secret key reference is not, so the last fix goes through `kubectl replace --force` with the full
corrected spec instead.
