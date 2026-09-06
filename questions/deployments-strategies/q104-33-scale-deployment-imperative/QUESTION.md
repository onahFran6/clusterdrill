# q104-33-scale-deployment-imperative: Scale a running Deployment with an imperative command

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-33-scale-deployment-imperative`

`setup.sh` already created a Deployment named `payments-api` (2 replicas, image
`nginx:1.25-alpine`, pod label `app=payments-api`) in namespace
`q104-33-scale-deployment-imperative`, and it is already fully rolled out with both replicas
Ready.

Scale `payments-api` up to exactly `5` replicas using the imperative `kubectl scale` command -
do not delete and recreate it, and do not rewrite it as a manifest. Wait until all 5 replicas
report Ready.

## Hint

Search kubernetes.io/docs for **"kubectl scale deployment"** - the Deployment concept page's
"Scaling a Deployment" section shows the exact imperative command.
