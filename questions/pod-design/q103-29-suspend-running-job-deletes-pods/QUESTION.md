# q103-29: Suspend a Job that is already running

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-29-suspend-running-job-deletes-pods`

`setup.sh` already created a Job named `report-builder` in namespace
`q103-29-suspend-running-job-deletes-pods`. Its container has been sleeping for
several minutes, and by the time you start this task the Job's pod has
already reached the `Running` phase - it is genuinely mid-execution, not
merely scheduled or pending.

An operator needs `report-builder` stopped right now, without deleting the
Job object itself (it will be resumed later). Suspend it by setting
`.spec.suspend` to `true` on the existing Job - do not delete the Job, do
not delete the pod directly, and do not scale anything.

The Job is considered suspended only once it reports zero active pods
(`.status.active` absent or `0`) and no pods remain for it in the
namespace.

## Hint

Search kubernetes.io/docs for **"job suspend field"** - the Jobs concept
page's "Suspending a Job" section explains what happens to a Job's *already
running* pods when `.spec.suspend` is set to `true` on a Job that has
already started, versus a Job that was created suspended from the start.
