# q110-19: reference solution

Doc: https://helm.sh/docs/helm/helm_upgrade/#options

```sh
helm upgrade --install flags \
  $HOME/practice-work/q110-19-helm-upgrade-install-idempotent/chart \
  -n q110-19-helm-upgrade-install-idempotent \
  --set featureFlag=on --wait
```
