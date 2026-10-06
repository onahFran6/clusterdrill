# q111-05: reference solution

Doc: https://kubernetes.io/docs/reference/kubectl/generated/kubectl_rollout_restart/

```sh
kubectl rollout restart deployment/greeter -n q111-05-rollout-restart-stale-env
kubectl rollout status deployment/greeter -n q111-05-rollout-restart-stale-env --timeout=60s
```

`rollout restart` stamps a `restartedAt` annotation onto the pod template. That is a template
change, so it triggers a normal rolling update (a new revision, old pods replaced one at a time)
without editing anything by hand. Env vars are read once at container start; a ConfigMap change
alone is not a pod-template change, so it never causes a rollout on its own. A ConfigMap mounted
as a volume does update in place after a short delay (unless mounted via `subPath`) - env vars
never do.
