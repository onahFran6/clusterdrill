# q101-01: Create a pod imperatively

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q101-01-create-pod-imperative`

A teammate needs a scratch pod to poke at quickly, and there's no time to hand-write a manifest.

In namespace `q101-01-create-pod-imperative`, create a single pod named `web-scratch` running image
`nginx:1.25-alpine`, using a single imperative `kubectl` command (no YAML file authored by hand).

## Hint

Search kubernetes.io/docs for **"kubectl run generators"** - the `kubectl run` reference page
shows the minimal form for starting a single pod from an image.
