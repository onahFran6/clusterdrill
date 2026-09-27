# q101-20: Create a Pod with restartPolicy Never

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q101-20-generate-pod-restart-policy`

In namespace `q101-20-generate-pod-restart-policy`, create a Pod named `one-shot-task` that:

- runs image `busybox:1.36`
- runs the command `echo done`
- has `spec.restartPolicy` set to `Never`

Generate a manifest first (client-side dry run is fine), edit it as needed, then create the Pod
from the edited YAML. The grader only checks the live object's final state.

## Hint

Search kubernetes.io/docs for **"pod restartPolicy"** - the Pod Lifecycle concept page documents
the three valid values, and the `kubectl run` reference confirms there's no direct flag for it.
