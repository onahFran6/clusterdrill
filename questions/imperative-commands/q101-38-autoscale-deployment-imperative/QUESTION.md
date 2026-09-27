# q101-38: Autoscale a Deployment imperatively

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q101-38-autoscale-deployment-imperative`

A Deployment named `api-server` (image `nginx:1.25-alpine`, 2 replicas) already exists in
namespace `q101-38-autoscale-deployment-imperative`.

Create a HorizontalPodAutoscaler for it named `api-server` that keeps the replica count between
`2` and `5`, targeting `60%` average CPU utilization, using a single imperative
`kubectl autoscale deployment` command (no manifest authored by hand).

## Hint

Search kubernetes.io/docs for **"kubectl autoscale"** - the Horizontal Pod Autoscaler walkthrough
shows the `kubectl autoscale deployment --min --max --cpu-percent` form for creating an HPA
without writing YAML.
