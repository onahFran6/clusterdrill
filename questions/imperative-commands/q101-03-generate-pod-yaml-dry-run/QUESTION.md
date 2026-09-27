# q101-03: Generate a Pod manifest, then create it

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q101-03-generate-pod-yaml-dry-run`

In namespace `q101-03-generate-pod-yaml-dry-run`, you need a starting-point Pod manifest without
creating the object on the API server first.

1. Generate YAML for a Pod named `yaml-seed` using image `redis:7-alpine`, with a client-side dry
   run so nothing is created by that step.
2. From that generated YAML (edited or piped as you like), create the Pod for real in the same
   namespace.

The grader only checks that `yaml-seed` exists and runs the right image.

## Hint

Search kubernetes.io/docs for **"kubectl run dry-run client -o yaml"** - the `kubectl run`
reference page documents the `--dry-run` and `-o yaml` flags together for generating a manifest
without creating the object.
