# q107-35-events-field-selector-filter: reference solution

Doc: https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#get

```sh
mkdir -p "$HOME/practice-work/q107-35-events-field-selector-filter"

kubectl get events -n q107-35-events-field-selector-filter \
  --field-selector involvedObject.name=broken-app,type=Warning \
  -o custom-columns=OBJECT:.involvedObject.name --no-headers \
  > "$HOME/practice-work/q107-35-events-field-selector-filter/broken-app-warnings.txt"
```
