# q101-22: Create a Pod with multiple named container ports

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q101-22-create-pod-multiple-ports-imperative`

In namespace `q101-22-create-pod-multiple-ports-imperative`, create a Pod named `multiport-app`
running image `nginx:1.25-alpine` whose single container exposes two named container ports:

- `8080` named `http`
- `8443` named `https`

Do this with a single imperative `kubectl run` invocation (no manifest written from scratch and
applied by hand).

## Hint

Search kubernetes.io/docs for **"kubectl run overrides"** - the `kubectl run` reference documents
the `--overrides` flag for merging an inline JSON patch into the generated pod spec, and the Pod
concept page's "Ports" section shows the `containerPort`/`name` schema shape to put in that patch.
