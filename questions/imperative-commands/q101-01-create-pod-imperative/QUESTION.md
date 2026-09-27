# q101-01: Create a Pod imperatively

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q101-01-create-pod-imperative`

In namespace `q101-01-create-pod-imperative`, create a Pod named `web-scratch` running image
`nginx:1.25-alpine`. Use a single imperative `kubectl` command - do not hand-write a YAML
manifest.

## Hint

Search kubernetes.io/docs for **"kubectl run generators"** - the `kubectl run` reference page
shows the minimal form for starting a single pod from an image.
