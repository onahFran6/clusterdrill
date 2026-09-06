# q110-25: Diagnose and fix a failing Helm pre-install hook blocking installation

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q110-25-helm-broken-hook-preinstall`

`setup.sh` staged a local Helm chart named `gatekeeper` at
`questions/helm-crds/q110-25-helm-broken-hook-preinstall/chart` (relative to `practice-bank/`).
The chart has two templates:

- `templates/deployment.yaml` - a normal single-replica Deployment running `nginx:1.25-alpine`.
- `templates/pre-install-job.yaml` - a Job annotated `helm.sh/hook: pre-install` (with
  `helm.sh/hook-delete-policy: before-hook-creation`) that runs image `busybox:1.36` and execs
  `["sh", "-c", "exit 1"]`.

No release has been installed yet. If you attempt `helm install gate
questions/helm-crds/q110-25-helm-broken-hook-preinstall/chart -n
q110-25-helm-broken-hook-preinstall --wait` right now, it will fail: Helm runs pre-install hooks
before any other template, and this Job's container deliberately exits `1`, so the hook never
succeeds and the release never installs.

Fix the chart on disk so the pre-install hook succeeds, then install it:

1. Edit `chart/templates/pre-install-job.yaml` so the Job's container command exits `0` instead
   of `1` (for example `["sh", "-c", "echo ready && exit 0"]`). Keep the
   `helm.sh/hook: pre-install` and `helm.sh/hook-delete-policy: before-hook-creation` annotations
   intact - do not remove the hook.
2. Install the fixed chart into namespace `q110-25-helm-broken-hook-preinstall` as release
   `gate`.

## Hint

Search kubernetes.io/docs for **"helm hooks pre-install"** - the Helm "Chart Hooks" docs explain
that `pre-install` hook resources run and must succeed before the rest of a chart's resources are
created, and that `helm.sh/hook-delete-policy: before-hook-creation` controls when a prior hook
Job is cleaned up.
