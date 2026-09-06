# q101-06: Create a Deployment imperatively with a replica count

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q101-06-create-deployment-imperative`

In namespace `q101-06-create-deployment-imperative`, create a Deployment named `api-server` that:

- runs image `nginx:1.25-alpine`
- starts with `3` replicas

Use imperative `kubectl` commands only (a `create` plus a follow-up scale/edit command is fine,
but no hand-written Deployment YAML).

## Hint

Search kubernetes.io/docs for **"kubectl create deployment replicas"** - the `kubectl create
deployment` reference shows the flag for setting the initial replica count at creation time.
