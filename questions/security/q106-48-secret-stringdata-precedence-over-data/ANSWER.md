# q106-48-secret-stringdata-precedence-over-data: reference solution

Doc: https://kubernetes.io/docs/concepts/configuration/secret/#restriction-precedence-rules-for-stringdata

`stringData` is a write-only convenience field: when a key appears in both `data` and
`stringData` on the same apply/patch, the API server uses the `stringData` value and discards the
`data` entry for that key - other keys already in `data` are left alone.

```sh
kubectl patch secret app-secret -n q106-48-secret-stringdata-precedence-over-data \
  --type=merge \
  -p '{"stringData":{"PASSWORD":"fresh-pw"}}'
```
