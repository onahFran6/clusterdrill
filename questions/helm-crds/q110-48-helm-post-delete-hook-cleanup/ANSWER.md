# q110-48-helm-post-delete-hook-cleanup: reference solution

Doc: https://helm.sh/docs/topics/charts_hooks/

```sh
CHART=questions/helm-crds/q110-48-helm-post-delete-hook-cleanup/chart
NS=q110-48-helm-post-delete-hook-cleanup

sed -i.bak 's/exit 1/exit 0/' "$CHART/templates/postdelete.yaml"
rm -f "$CHART/templates/"*.bak

# helm uninstall runs hooks from the release's already-stored manifest, not
# from the chart directory on disk - upgrade first to refresh it.
helm upgrade demo "$CHART" -n "$NS" --wait

helm uninstall demo -n "$NS"
```
