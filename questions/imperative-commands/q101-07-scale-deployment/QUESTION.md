# q101-07: Scale an existing Deployment

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q101-07-scale-deployment`

`setup.sh` already created a Deployment named `worker-pool` (image `busybox:1.36`, 2 replicas) in
namespace `q101-07-scale-deployment`.

Using a single imperative `kubectl` command, scale `worker-pool` to `5` replicas.

## Hint

Search kubernetes.io/docs for **"kubectl scale deployment"** - the `kubectl scale` command
reference shows how to change a Deployment's replica count without editing YAML.
