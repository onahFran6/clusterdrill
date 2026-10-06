# q113-17-and-vs-or-selector-semantics: reference solution

Doc: https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.30/#networkpolicypeer-v1-networking-k8s-io

```sh
QUESTION_ID=q113-17-and-vs-or-selector-semantics

kubectl patch networkpolicy allow-scrapers -n "$QUESTION_ID" --type=json -p='[
  {"op": "replace", "path": "/spec/ingress/0/from", "value": [
    {
      "namespaceSelector": {"matchLabels": {"team": "monitoring"}},
      "podSelector": {"matchLabels": {"role": "scraper"}}
    }
  ]}
]'
```

The broken version had two separate `from` list items - "any pod in a `team=monitoring`
namespace" OR "any pod labeled `role=scraper` in this policy's own namespace" (a bare
`podSelector` in a `from` entry only ever matches pods in the policy's own namespace, never
another one). That let through every pod in a monitoring namespace regardless of its own labels,
and every locally-labelled scraper regardless of which namespace it ran in. Folding both
selectors onto one `from` entry makes them AND together: only a pod that is simultaneously
`role=scraper` and running in a `team=monitoring`-labelled namespace matches.
