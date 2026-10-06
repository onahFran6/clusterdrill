# q115-02: reference solution

Doc: https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/#add-imagepullsecrets-to-a-service-account

```sh
NS=q115-02-pull-secrets-via-serviceaccount

kubectl create secret docker-registry regcred \
  --docker-server=registry.example.com \
  --docker-username=ci-bot \
  --docker-password='S3cret!pw' \
  -n "$NS"

kubectl patch serviceaccount builder -n "$NS" \
  -p '{"imagePullSecrets":[{"name":"regcred"}]}'

# apply the Pod AFTER patching the ServiceAccount - inheritance only
# happens at the Pod's own creation time
cat <<EOF | kubectl apply -n "$NS" -f -
apiVersion: v1
kind: Pod
metadata:
  name: app
  labels:
    clusterdrill-question: $NS
spec:
  serviceAccountName: builder
  containers:
    - name: app
      image: registry.example.com/team/app:1.0
EOF

kubectl get pod app -n "$NS" -o jsonpath='{.spec.imagePullSecrets}'   # [{"name":"regcred"}]
```

The ServiceAccount's `imagePullSecrets` are copied into a Pod only when that Pod is **created** -
a Pod that already existed before the patch would never pick it up. The Secret holds the same
JSON `docker login` writes to `~/.docker/config.json`; you can build one from that file directly
with `--from-file=.dockerconfigjson=... --type=kubernetes.io/dockerconfigjson` instead of the
`docker-registry` generator. `registry.example.com` doesn't exist, so `app` stays in
`ImagePullBackOff` forever - that's expected, and the lesson here is the inherited
`imagePullSecrets` wiring, not Pod readiness.
