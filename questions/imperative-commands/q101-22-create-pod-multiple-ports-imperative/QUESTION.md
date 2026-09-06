# q101-22-create-pod-multiple-ports-imperative: Create a pod with multiple named container ports imperatively

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q101-22-create-pod-multiple-ports-imperative`

In namespace `q101-22-create-pod-multiple-ports-imperative`, create a pod named `multiport-app`
running image `nginx:1.25-alpine` whose single container exposes two named container ports:

- `8080` named `http`
- `8443` named `https`

Do this with a single imperative `kubectl run` invocation - `--port` only accepts one port, so
you'll need to merge the extra port fields in some other imperative way (no manifest written from
scratch and applied by hand).

## Hint

Search kubernetes.io/docs for **"kubectl run overrides"** - the `kubectl run` reference documents
the `--overrides` flag for merging an inline JSON patch into the generated pod spec, and the Pod
concept page's "Ports" section shows the `containerPort`/`name` schema shape to put in that patch.
