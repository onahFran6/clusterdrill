# q104-22: Shorten how long a stalled rollout may run

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-22-set-progress-deadline`

A Deployment named `image-resizer` already exists in namespace
`q104-22-set-progress-deadline` with 2 replicas of image `nginx:1.25-alpine`, using the
default RollingUpdate strategy. It has no explicit `progressDeadlineSeconds` (the API default
is 600).

Set `spec.progressDeadlineSeconds` on `image-resizer` to `120`. Do not change any other field.

## Hint

Search kubernetes.io/docs for **"progressDeadlineSeconds"** - the Deployments concept page
explains how this field controls how long the Deployment controller waits before reporting a
stalled rollout, and `kubectl patch` can set it directly.
