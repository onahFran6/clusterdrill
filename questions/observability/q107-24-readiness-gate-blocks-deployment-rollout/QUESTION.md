# q107-24-readiness-gate-blocks-deployment-rollout: Diagnose a Deployment rollout stuck because new pods never turn Ready

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-24-readiness-gate-blocks-deployment-rollout`

`setup.sh` already created a Deployment named `checkout-api` in namespace
`q107-24-readiness-gate-blocks-deployment-rollout` running 3 replicas of `nginx:1.25-alpine`
behind a working `readinessProbe`. A rollout to a new image tag was then triggered and is stuck:

- `kubectl rollout status deployment/checkout-api -n q107-24-readiness-gate-blocks-deployment-rollout`
  hangs, waiting for the rollout to finish.
- `kubectl get deployment checkout-api -n q107-24-readiness-gate-blocks-deployment-rollout` shows
  `UP-TO-DATE` less than `3`.
- The new ReplicaSet's pod(s) are stuck, never reaching `Ready`.

Investigate and fix it:

1. Run `kubectl rollout status`, `kubectl describe pod` on the failing new pod, and
   `kubectl rollout history deployment/checkout-api -n q107-24-readiness-gate-blocks-deployment-rollout`
   to find the root cause.
2. Correct the container image tag back to `nginx:1.25-alpine` (for example with
   `kubectl set image deployment/checkout-api nginx=nginx:1.25-alpine -n q107-24-readiness-gate-blocks-deployment-rollout`,
   or by editing the Deployment).
3. Do **not** fix this by rolling back to the original revision (`kubectl rollout undo`) - the
   Deployment's pod template must end up on the corrected tag `nginx:1.25-alpine`, reached by
   fixing the bad rollout forward, not by reverting to whatever image the Deployment ran before
   the update.
4. Wait for the rollout to complete: all 3 replicas must be `updatedReplicas`, `readyReplicas`,
   and `availableReplicas`, all running the corrected image.

## Hint

Search kubernetes.io/docs for **"checking rollout status"** - the Deployments concept page's
"Checking Rollout Status" and "Rolling Back a Deployment" sections show how a bad
`kubectl set image` update leaves old pods running while new pods fail, and how
`kubectl rollout history` and `kubectl describe pod` reveal why.
