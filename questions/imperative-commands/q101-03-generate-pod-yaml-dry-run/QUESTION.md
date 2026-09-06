# q101-03: Generate a pod manifest with a client-side dry run

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q101-03-generate-pod-yaml-dry-run`

You need a starting-point manifest to hand-edit later, without ever hitting the API server to
create the object first.

In namespace `q101-03-generate-pod-yaml-dry-run`:

1. Generate the YAML for a pod named `yaml-seed` using image `redis:7-alpine`, using a
   client-side dry run so nothing is actually created on the API server by that command.
2. Using that generated YAML (edited or piped as you see fit), create the pod for real in the
   same namespace.

The end state the grader checks is simply that `yaml-seed` exists and runs the right image - how
you get the YAML onto disk or into `kubectl apply` is up to you, as long as the generation step
itself was a client-side dry run.

## Hint

Search kubernetes.io/docs for **"kubectl run dry-run client -o yaml"** - the `kubectl run`
reference page documents the `--dry-run` and `-o yaml` flags together for generating a manifest
without creating the object.
