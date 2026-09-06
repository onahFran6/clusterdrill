# q110-12: reference solution

Doc: https://kubernetes.io/docs/reference/kubectl/jsonpath/

```sh
kubectl get playlists -n q110-12-crd-jsonpath-field \
  -o jsonpath='{range .items[*]}{.metadata.name}{"="}{.spec.trackCount}{"\n"}{end}'
# road-trip=12, focus=47, workout=23 -> "focus" has the highest trackCount

kubectl create configmap inspected-playlist -n q110-12-crd-jsonpath-field \
  --from-literal=winner=focus
```
