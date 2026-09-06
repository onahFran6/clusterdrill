# q101-46-fix-stuck-rollout-bad-readiness-probe: Diagnose and fix a Deployment stuck at 0 ready replicas from a bad readiness probe path

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q101-46-fix-stuck-rollout-bad-readiness-probe`

`setup.sh` already created a Deployment named `web-front` (image `nginx:1.25-alpine`, 3 replicas)
in namespace `q101-46-fix-stuck-rollout-bad-readiness-probe`. Every pod is `Running` but none of
them ever turn `Ready`, so the Deployment never finishes rolling out.

Diagnose why using `kubectl describe pod` on one of `web-front`'s pods and/or `kubectl get events`,
then fix it imperatively - `kubectl set` has no subcommand for editing probes, so generate the
Deployment's manifest with a client-side dry run (or use `kubectl edit`), fix the readiness probe's
HTTP path so it points at a path nginx actually serves (`/`), and apply it - so that:

- `web-front` keeps the same image, replica count, and container name.
- `web-front` reaches `status.readyReplicas=3`.

## Hint

Search kubernetes.io/docs for **"configure liveness readiness startup probes"** - the Configure
Probes task page shows the `httpGet.path`/`port` fields a readiness probe checks, and how a wrong
path leaves every container `Running` but perpetually not `Ready`.
