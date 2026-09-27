# q107-24-readiness-gate-blocks-deployment-rollout: Diagnose a Deployment rollout stuck because new pods never turn Ready

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-24-readiness-gate-blocks-deployment-rollout`

A Deployment named `checkout-api` already exists in namespace
`q107-24-readiness-gate-blocks-deployment-rollout` with 3 replicas. A rollout away from image
`nginx:1.25-alpine` is stuck: rollout status does not finish, `UP-TO-DATE` is less than `3`, and
the new ReplicaSet's pods never become `Ready`.

Fix the rollout forward:

- set the container image back to `nginx:1.25-alpine`
- do not undo the rollout to the previous revision
- all 3 replicas must be `updatedReplicas`, `readyReplicas`, and `availableReplicas`, running the
  corrected image

## Hint

Search kubernetes.io/docs for **"checking rollout status"** - the Deployments concept page's
"Checking Rollout Status" and "Rolling Back a Deployment" sections show how a bad image update
leaves old pods running while new pods fail, and how `kubectl rollout history` and
`kubectl describe pod` reveal why. `kubectl set image deployment/checkout-api
nginx=nginx:1.25-alpine -n q107-24-readiness-gate-blocks-deployment-rollout` fixes the tag in
place. Undoing would restore whatever image ran before this update, which is not the required
end state.
