# q111-03: Resources and autoscaling

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q111-03-resources-then-autoscale`

Team Mars's `ingest` Deployment (seeded, 2 replicas) gets traffic spikes every evening. They want
it to scale by itself.

- Each container requests **200m** CPU and **128Mi** memory, and is limited to **500m** CPU and
  **256Mi** memory.
- Create a HorizontalPodAutoscaler named `ingest` that keeps between **2** and **6** replicas,
  targeting **70%** average CPU utilisation.
- Read the HPA back afterward and confirm min, max, and CPU target are **2**, **6**, **70**.

## Hint

Search kubernetes.io/docs for **"kubectl autoscale"**. Utilisation is measured against the
container's own CPU *request*, so the resources step has to come first - 70% of what, otherwise?
Check `kubectl autoscale -h` for the CPU-target flag your kubectl version actually uses.
