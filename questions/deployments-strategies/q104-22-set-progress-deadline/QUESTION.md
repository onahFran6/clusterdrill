# q104-22-set-progress-deadline: Set a Deployment's progressDeadlineSeconds

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-22-set-progress-deadline`

A Deployment named `image-resizer` already exists in the `q104-22-set-progress-deadline` namespace with 2 replicas, running image `nginx:1.25-alpine`, using the default RollingUpdate strategy. It currently has no `progressDeadlineSeconds` set (so it defaults to 600).

Update the `image-resizer` Deployment so that `spec.progressDeadlineSeconds` is set to `120`. Do not change any other field of the Deployment.

## Hint

Search kubernetes.io/docs for **"progressDeadlineSeconds"** - the Deployments concept page explains how this field controls how long the Deployment controller waits before reporting a stalled rollout, and `kubectl patch` can set it directly.
