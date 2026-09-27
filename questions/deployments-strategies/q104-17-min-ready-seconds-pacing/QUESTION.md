# q104-17: Pace when new pods count as available during a rollout

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-17-min-ready-seconds-pacing`

A Deployment named `event-bus` (image `nginx:1.24-alpine`, 3 replicas) already exists in
namespace `q104-17-min-ready-seconds-pacing`, fully rolled out.

Set `event-bus`'s `minReadySeconds` to `10`, then roll it out to image `nginx:1.25-alpine` and
confirm the rollout completes successfully.

## Hint

Search kubernetes.io/docs for **"deployment minReadySeconds"** - the Deployment concept page
explains how this field delays when a pod counts as available after it passes readiness. That
buffer keeps a brief flap right after start from advancing the rollout too quickly.
