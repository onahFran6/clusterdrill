# q105-47-resourcequota-scope-besteffort: Get a second pod past a BestEffort-scoped ResourceQuota

**Domain:** Application Environment, Configuration and Security · **Points:** 5 · **Namespace:** `q105-47-resourcequota-scope-besteffort`

Namespace `q105-47-resourcequota-scope-besteffort` already has:

- a `ResourceQuota` named `besteffort-quota` scoped to `BestEffort` pods only (`spec.scopes:
  [BestEffort]`), with `hard.pods: "1"` - it only counts and limits pods that specify **no**
  resource requests or limits at all,
- a running pod named `existing-besteffort` (image `busybox:1.36`, running `sleep 3600`) that
  already has no resource requests or limits, already consuming that quota's one available
  `BestEffort` pod slot.

A second pod manifest is sitting on disk at `~/extra-pod.yaml` (name `extra-worker`, image
`busybox:1.36`, running `sleep 3600`), also with no resources set. Applying it as-is is rejected -
`besteffort-quota` only has room for one `BestEffort` pod, and `existing-besteffort` already holds
it.

Get `extra-worker` running **without** deleting, modifying, or restarting `existing-besteffort`,
and **without** raising `besteffort-quota`'s `hard.pods` limit. Do it by editing `~/extra-pod.yaml`
to add explicit CPU and memory requests **and** limits to its container (any values are fine) -
once a pod specifies its own requests and limits it is no longer `BestEffort`, so it falls outside
this quota's scope entirely and its `pods: "1"` cap no longer applies to it. Apply the edited
manifest as pod `extra-worker`; it must reach `Running`.

## Hint

Search kubernetes.io/docs for **"resource quota scopes"** - the Resource Quotas concept page's
"Resource Quota Scopes" section explains that a `BestEffort`-scoped quota only matches pods with
no resource requests/limits at all, and any pod with explicit requests/limits is exempt from it.
