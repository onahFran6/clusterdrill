# q104-26-poddisruptionbudget-minavailable: Protect a Deployment's availability during voluntary disruptions

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-26-poddisruptionbudget-minavailable`

`setup.sh` already created a Deployment named `checkout-svc` (3 replicas, image `busybox:1.36`,
command `sleep 3600`, pod label `app=checkout-svc`) in namespace
`q104-26-poddisruptionbudget-minavailable`. Nothing currently protects it from voluntary
disruptions (e.g. node drains) taking down too many of its pods at once.

Create a PodDisruptionBudget named `checkout-svc-pdb` in the same namespace that selects pods
labeled `app=checkout-svc` and guarantees at least `2` of them stay available at any time.

## Hint

Search kubernetes.io/docs for **"PodDisruptionBudget"** - the Disruptions concept page's "Specifying
a PodDisruptionBudget" section shows the `minAvailable` field and how its `selector` targets the
same pod labels a Deployment already uses.
