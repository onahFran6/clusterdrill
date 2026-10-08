# q118-09: Stop retrying invalid input

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q118-09-pod-failure-policy-skips-pointless-retries`

Team Ceres needs *Job* `validate` using `busybox:1.36` and `sh -c 'echo invalid input; exit 3'`.
Exit code **3** must fail the whole Job immediately, while other failures retain a budget of **4** retries.
Use a controller-visible failed Pod for each attempt and confirm only one Pod was created.
This exercise covers a CKAD stretch feature available from Kubernetes 1.31.

## Hint

Search kubernetes.io/docs for "Pod failure policy exit codes" and the supported restart policy.
