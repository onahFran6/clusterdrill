# q103-17: Auto-clean a Job a fixed time after it finishes

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-17-job-ttl-after-finished`

Photon Research Group runs a one-shot calibration check for every new detector batch. Completed
Jobs pile up in the namespace if nobody removes them, and nobody's going to remember to clean up
each batch's Job by hand.

In namespace `q103-17-job-ttl-after-finished`, create a Job named `self-cleaning` using image
`busybox:1.36` running command `echo done`, that removes itself on its own **10** seconds after
it finishes - no one should ever have to delete it manually.

Do not delete the Job yourself. It must disappear on its own after it completes.

## Hint

Search kubernetes.io/docs for **"clean up finished jobs automatically"** - the Jobs concept page
has a section by that exact name covering the one spec field for this.
