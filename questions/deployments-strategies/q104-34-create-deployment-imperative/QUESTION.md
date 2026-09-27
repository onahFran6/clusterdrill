# q104-34: Create a Deployment with one imperative command

**Domain:** Application Deployment · **Points:** 5 · **Namespace:** `q104-34-create-deployment-imperative`

Namespace `q104-34-create-deployment-imperative` is empty - create everything yourself.

Using a single imperative `kubectl create deployment` command (no YAML manifest), create a
Deployment named `frontend` running `3` replicas of image `nginx:1.25-alpine`. Wait until all 3
replicas report Ready.

## Hint

Search kubernetes.io/docs for **"kubectl create deployment"** - the `kubectl create deployment`
command reference shows the `--image` and `--replicas` flags for creating a Deployment in one line.
