# q101-20: Generate a manifest to set a field `kubectl run` can't set directly

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q101-20-generate-pod-restart-policy`

`kubectl run` defaults a bare pod to `restartPolicy: Always`, and offers no flag to change it -
you can only get `Never` or `OnFailure` by generating the YAML and editing it before creating the
object (this is exactly the "generator + edit" pattern the exam expects you to know, not a
one-liner flag).

In namespace `q101-20-generate-pod-restart-policy`:

1. Use `kubectl run` with a client-side dry run to generate the YAML for a pod named
   `one-shot-task`, image `busybox:1.36`, command `echo done`.
2. Edit the generated YAML so `spec.restartPolicy` is `Never`.
3. Create the pod for real from that edited YAML.

The grader only checks the live object's final state - `restartPolicy: Never`, the right name,
image, and command - not which editor or intermediate file you used.

## Hint

Search kubernetes.io/docs for **"pod restartPolicy"** - the Pod Lifecycle concept page documents
the three valid values, and the `kubectl run` reference confirms there's no direct flag for it.
