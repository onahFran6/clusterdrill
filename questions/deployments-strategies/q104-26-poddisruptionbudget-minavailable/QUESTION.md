# q104-26: Keep at least two pods available during drains

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-26-poddisruptionbudget-minavailable`

A Deployment named `checkout-svc` already exists in namespace
`q104-26-poddisruptionbudget-minavailable` with 3 replicas of image `busybox:1.36` (command
`sleep 3600`, pod label `app=checkout-svc`). Nothing currently limits how many of those pods
voluntary disruptions (such as node drains) may take down at once.

Create a PodDisruptionBudget named `checkout-svc-pdb` in the same namespace that selects pods
labeled `app=checkout-svc` and keeps at least `2` of them available.

## Hint

Search kubernetes.io/docs for **"PodDisruptionBudget"** - the Disruptions concept page's
"Specifying a PodDisruptionBudget" section shows the `minAvailable` field and how its
`selector` targets the same pod labels a Deployment already uses.
