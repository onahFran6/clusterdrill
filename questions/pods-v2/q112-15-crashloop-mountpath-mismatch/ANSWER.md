# q112-15: reference solution

Doc: https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/#debugging-crashloopbackoff

```sh
NS=q112-15-crashloop-mountpath-mismatch

kubectl get pod calc -n "$NS" -o jsonpath='{.status.containerStatuses[0].lastState.terminated.exitCode}'
echo
kubectl logs calc -n "$NS" --previous

kubectl replace --force -n "$NS" -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: calc
  labels:
    clusterdrill-question: $NS
spec:
  volumes:
    - name: conf
      configMap:
        name: app-conf
  containers:
    - name: calc
      image: busybox:1.36
      command: ["sh", "-c", "cat /config/app.conf && sleep 3600"]
      volumeMounts:
        - name: conf
          mountPath: /config
EOF

kubectl wait --for=condition=Ready pod/calc -n "$NS" --timeout=60s
```

`CrashLoopBackOff` is a symptom, not a cause - the container starts, exits, and gets restarted
with a growing backoff delay. `--previous` and `lastState` are what show what the *dead* container
actually said (`cat: can't open '/config/app.conf': No such file or directory`), since the current
container may already be back in its own backoff window with nothing useful in its live logs. A
mount path can't be patched on a live Pod, so the fix goes through `kubectl replace --force`
instead of an in-place edit.
