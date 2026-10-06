# q112-17: reference solution

Doc: https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#pod-phase

```sh
NS=q112-17-restart-policies-and-exit-codes

kubectl run once    --image=busybox:1.36 --restart=Never     -n "$NS" -- sh -c 'echo done; exit 0'
kubectl run retry   --image=busybox:1.36 --restart=OnFailure -n "$NS" -- sh -c 'echo failing; exit 2'
kubectl run forever --image=busybox:1.36                     -n "$NS" -- sh -c 'echo done; exit 0'

sleep 30
kubectl get pods -n "$NS" -o custom-columns=NAME:.metadata.name,PHASE:.status.phase,\
RESTARTS:.status.containerStatuses[0].restartCount,\
EXIT:.status.containerStatuses[0].lastState.terminated.exitCode
```

| Pod | Phase (API field) | STATUS column | Restarts |
|---|---|---|---|
| `once` | `Succeeded` | `Completed` | 0 |
| `retry` | `Running` | `CrashLoopBackOff` / `Error` | growing |
| `forever` | `Running` | `CrashLoopBackOff` / `Completed` | growing |

For `once`, the exit code lives under `state.terminated` rather than `lastState.terminated`,
because it never restarted - `lastState` stays empty. `Always` restarts a container even after a
clean `exit 0`, which is exactly why a Deployment (which always uses `restartPolicy: Always`)
can never run a genuine one-shot task - that is what Jobs exist for.
