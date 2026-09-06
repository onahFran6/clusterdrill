# q107-23-terminationMessage-custom-path: Configure a custom terminationMessagePath so a failing container's exit reason is captured

**Domain:** Application Observability and Maintenance · **Points:** 5 · **Namespace:** `q107-23-terminationmessage-custom-path`

`setup.sh` already created a pod named `batch-validator` (image `busybox:1.36`, `restartPolicy: Never`,
command `sh -c 'echo "validation failed: schema mismatch on field age" > /dev/termination-log; exit 1'`)
in namespace `q107-23-terminationmessage-custom-path`. The container's script writes its failure
reason to the default termination-log path, but the container's `terminationMessagePath` field was
mis-set to `/tmp/nonexistent/term.log` - a path the script never writes to. Because of this,
`kubectl describe pod batch-validator` shows an empty `Message:` under Last State/Terminated even
though the script clearly produced one.

Fix the pod so Kubernetes captures the message. Edit the container's `terminationMessagePath` back
to the default `/dev/termination-log`, then delete and recreate the pod so the container re-runs
with the corrected field (this field is immutable on a running pod - obtain the manifest with
`kubectl get pod batch-validator -n q107-23-terminationmessage-custom-path -o yaml`, edit, delete,
and reapply). Keep the pod named `batch-validator`, in the same namespace, with the same image,
command, and `restartPolicy: Never`. After it terminates, its container status must report the
`schema mismatch` message.

## Hint

Search kubernetes.io/docs for **"Customizing the termination message"** - the Determine the Reason
for Pod Failure task shows the `terminationMessagePath` and `terminationMessagePolicy` container
fields and how Kubernetes reads `/dev/termination-log` by default to populate
`status.containerStatuses[].state.terminated.message`.
