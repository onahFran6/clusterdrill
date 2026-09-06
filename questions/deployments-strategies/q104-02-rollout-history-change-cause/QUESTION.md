# q104-02: Record a rollout's change-cause and confirm rollout history

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-02-rollout-history-change-cause`

`setup.sh` already created a Deployment named `pricing` (image `nginx:1.24-alpine`, 3 replicas) in
namespace `q104-02-rollout-history-change-cause`.

Update `pricing`'s container image to `nginx:1.25-alpine`, and make sure this change shows up
in `kubectl rollout history deployment/pricing` with the change-cause text
`update nginx to 1.25-alpine` recorded against the new revision. Wait for the rollout to finish
before you're done.

## Hint

Search kubernetes.io/docs for **"kubectl annotate deployment change-cause"** - the "Checking
Rollout History of a Deployment" section of the Deployment concept page shows how the
`kubernetes.io/change-cause` annotation feeds the `CHANGE-CAUSE` column in rollout history.

