# q112-01: reference solution

Doc: https://kubernetes.io/docs/tasks/inject-data-application/define-command-argument-container/

```sh
cat <<'EOF' | kubectl apply -n q112-01-command-versus-args -f -
apiVersion: v1
kind: Pod
metadata:
  name: heartbeat
  labels:
    app: heartbeat
    tier: tools
    clusterdrill-question: q112-01-command-versus-args
spec:
  containers:
    - name: heartbeat
      image: busybox:1.36
      command: ["sh", "-c"]
      args: ["while true; do echo beat from io; sleep 5; done"]
EOF

kubectl wait --for=condition=Ready pod/heartbeat -n q112-01-command-versus-args --timeout=60s
```

`command` replaces the image's ENTRYPOINT, and `args` replaces its CMD. Plain `kubectl run x --
a b` puts everything in `args`; `kubectl run x --command -- a b` puts everything in `command`.
Neither flag alone gives you a `["sh", "-c"]` command paired with a separate `args` loop - that
split only comes from editing the generated YAML.
