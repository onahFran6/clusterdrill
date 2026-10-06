# q115-03: reference solution

Doc: https://kubernetes.io/docs/concepts/containers/images/#image-names

```sh
NS=q115-03-pin-by-digest

D=$(kubectl get pods -n "$NS" -l app=web -o jsonpath='{.items[0].status.containerStatuses[0].imageID}')
# docker.io/library/nginx@sha256:...

DIGEST="${D#*@}"
kubectl set image deployment/web nginx="nginx@$DIGEST" -n "$NS"
kubectl rollout status deployment/web -n "$NS" --timeout=120s

kubectl get pods -n "$NS" -l app=web \
  -o jsonpath='{range .items[*]}{.status.containerStatuses[0].imageID}{"\n"}{end}'   # same digest on both pods

kubectl get deployment web -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].image}'
```

A tag is a movable label; a digest is a hash of the image manifest and can't change, which is
why an audit asking "run exactly these bytes" needs the digest, not the tag. `imageID` is what
the kubelet actually resolved and pulled, not what the spec asked for - the two only coincide by
chance once a tag's target has moved. A Deployment's pod template is mutable, so `kubectl set
image` is a normal patch here; that's unlike a bare Pod's `image` field, which only tolerates the
same kind of in-place swap because it's on a short allowlist of mutable fields, not because
Deployments and Pods behave the same way in general.
