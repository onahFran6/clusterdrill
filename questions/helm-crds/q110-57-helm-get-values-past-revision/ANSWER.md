# q110-57: reference solution

Doc: https://helm.sh/docs/helm/helm_get_values/

```sh
mkdir -p ~/practice-work/q110-57-helm-get-values-past-revision

helm get values app -n q110-57-helm-get-values-past-revision --revision 4 -o json \
  > ~/practice-work/q110-57-helm-get-values-past-revision/revision4-user.json

helm get values app -n q110-57-helm-get-values-past-revision --revision 4 --all -o json \
  > ~/practice-work/q110-57-helm-get-values-past-revision/revision4-all.json
```
