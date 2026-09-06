# q104-19: Autoscale a Deployment on CPU utilization

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-19-autoscale-deployment-cpu`

`setup.sh` already created a Deployment named `checkout-api` (image `nginx:1.25-alpine`, 3
replicas, each container already requesting `cpu: 100m`) in namespace
`q104-19-autoscale-deployment-cpu`.

Using a single imperative `kubectl autoscale` command, create a HorizontalPodAutoscaler for
`checkout-api` that:

- keeps replicas between `4` and `12`
- targets an average CPU utilization of `75%`

## Hint

Search kubernetes.io/docs for **"kubectl autoscale"** - the `kubectl autoscale` command
reference shows the `--min`/`--max`/`--cpu-percent` flags for creating a
HorizontalPodAutoscaler in one line.
