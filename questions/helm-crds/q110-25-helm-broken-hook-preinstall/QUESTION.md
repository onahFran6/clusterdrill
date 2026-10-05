# q110-25-helm-broken-hook-preinstall: Diagnose and fix a failing Helm pre-install hook blocking installation

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-25-helm-broken-hook-preinstall`

A local Helm chart named `gatekeeper` is at
`$HOME/practice-work/q110-25-helm-broken-hook-preinstall/chart`.
It templates a Deployment plus a Job annotated as a `pre-install` hook. No release is installed
yet. An install attempt fails because that pre-install hook does not succeed.

Fix the chart on disk so the pre-install hook succeeds, then install it into this namespace as
release `gate`. Keep the hook annotations on the Job - do not remove the hook. When done,
release `gate` must be deployed, Deployment `gate-gatekeeper` must have 1 available replica,
and the pre-install Job must have completed successfully.

## Hint

Search kubernetes.io/docs for **"helm hooks pre-install"** - pre-install hook resources must
succeed before the rest of the chart is created. Inspect the Job's container command in
`templates/pre-install-job.yaml`; a non-zero exit fails the hook. Keep
`helm.sh/hook: pre-install` and `helm.sh/hook-delete-policy: before-hook-creation`.
