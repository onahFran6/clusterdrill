# q104-45: Cap voluntary disruptions with a percentage PDB

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-45-poddisruptionbudget-maxunavailable-percent`

A Deployment named `catalog-svc` already exists in namespace
`q104-45-poddisruptionbudget-maxunavailable-percent` with 5 replicas of image `busybox:1.36`
(command `sleep 3600`, pod label `app=catalog-svc`). Nothing currently limits how many of those
pods voluntary disruptions (such as node drains) may take down at once.

Create a PodDisruptionBudget named `catalog-svc-pdb` in the same namespace that selects pods
labeled `app=catalog-svc` and allows at most `40%` of pods unavailable at once - use
`maxUnavailable` as a percentage, not `minAvailable` and not a fixed count.

## Hint

Search kubernetes.io/docs for **"PodDisruptionBudget maxUnavailable"** - the Disruptions concept
page's "Specifying a PodDisruptionBudget" section shows that `maxUnavailable` (like
`minAvailable`) accepts either an absolute number or a percentage string.
