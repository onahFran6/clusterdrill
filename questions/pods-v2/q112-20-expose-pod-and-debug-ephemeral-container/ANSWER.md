# q112-20: reference solution

Doc: https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/#ephemeral-container

```sh
NS=q112-20-expose-pod-and-debug-ephemeral-container

kubectl expose pod api --name=api-svc --port=80 --target-port=http -n "$NS"
kubectl label service api-svc "clusterdrill-question=$NS" -n "$NS"

sleep 3
kubectl run tmp --rm -i --restart=Never --image=curlimages/curl:8.10.1 -n "$NS" \
  -- curl -s --max-time 5 api-svc

kubectl debug api --image=busybox:1.36 --target=web -c dbg -n "$NS" -- ps
sleep 5
kubectl logs api -c dbg -n "$NS"
```

Ephemeral containers are added through a dedicated subresource, which is why they can join a Pod
whose spec is otherwise immutable - they can never be removed afterward, and they get no ports or
probes of their own. `kubectl expose pod` builds its Service selector straight from the Pod's own
labels, and `--target-port=http` resolves against the container's *named* port rather than a
literal number, so the container's actual port could change later without ever touching the
Service.
