# q110-41-helm-notes-txt-value-substitution: reference solution

Doc: https://helm.sh/docs/chart_template_guide/notes_files/

```sh
helm install demo questions/helm-crds/q110-41-helm-notes-txt-value-substitution/chart \
  -n q110-41-helm-notes-txt-value-substitution \
  --set appName=payments-api \
  --wait
```
