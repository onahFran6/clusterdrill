# q110-50-helm-values-schema-json-fix: reference solution

Doc: https://helm.sh/docs/topics/charts/#schema-files

```sh
CHART=questions/helm-crds/q110-50-helm-values-schema-json-fix/chart

python3 -c "
import json
with open('$CHART/values.schema.json') as f:
    schema = json.load(f)
schema['properties']['replicaCount']['maximum'] = 10
with open('$CHART/values.schema.json', 'w') as f:
    json.dump(schema, f, indent=2)
"

helm install demo "$CHART" \
  -n q110-50-helm-values-schema-json-fix \
  --set replicaCount=5 \
  --wait
```
