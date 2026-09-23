# q110-56: reference solution

Doc: https://helm.sh/docs/helm/helm_list/

```sh
mkdir -p ~/practice-work/q110-56-helm-list-all-namespaces-failed-filter

helm list -A -o json \
  > ~/practice-work/q110-56-helm-list-all-namespaces-failed-filter/all-releases.json

helm list -A --failed -o json \
  > ~/practice-work/q110-56-helm-list-all-namespaces-failed-filter/failed-releases.json
```
