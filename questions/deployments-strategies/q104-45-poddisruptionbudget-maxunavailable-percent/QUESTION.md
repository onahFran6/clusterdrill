# q104-45-poddisruptionbudget-maxunavailable-percent: Cap voluntary disruptions with a percentage-based PDB

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-45-poddisruptionbudget-maxunavailable-percent`

`setup.sh` already created a Deployment named `catalog-svc` (5 replicas, image `busybox:1.36`,
command `sleep 3600`, pod label `app=catalog-svc`) in namespace
`q104-45-poddisruptionbudget-maxunavailable-percent`. Nothing currently protects it from voluntary
disruptions (e.g. node drains) taking down too many of its pods at once.

Create a PodDisruptionBudget named `catalog-svc-pdb` in the same namespace that selects pods
labeled `app=catalog-svc` and allows **at most 40% of pods to be unavailable at once** - use
`maxUnavailable` as a percentage, not `minAvailable` and not a fixed count.

## Hint

Search kubernetes.io/docs for **"PodDisruptionBudget maxUnavailable"** - the Disruptions concept
page's "Specifying a PodDisruptionBudget" section shows that `maxUnavailable` (like
`minAvailable`) accepts either an absolute number or a percentage string.
