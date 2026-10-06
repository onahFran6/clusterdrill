# q110-34-helm-set-list-index-values: reference solution

Doc: https://helm.sh/docs/chart_template_guide/values_files/#deeply-nested-values

```sh
helm install demo $HOME/practice-work/q110-34-helm-set-list-index-values/chart \
  -n q110-34-helm-set-list-index-values \
  --set 'hosts[0]=api.example.com,hosts[1]=admin.example.com' \
  --wait
```
