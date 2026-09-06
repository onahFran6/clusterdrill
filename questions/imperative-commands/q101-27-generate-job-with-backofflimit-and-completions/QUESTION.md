# q101-27-generate-job-with-backofflimit-and-completions: Generate and patch a Job to require 4 successful completions with limited parallelism and retries

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q101-27-generate-job-with-backofflimit-and-completions`

In namespace `q101-27-generate-job-with-backofflimit-and-completions`, create a Job named
`batch-verify` that runs image `busybox:1.36` with the command `sh -c "echo verifying && exit 0"`.

The Job must require **4 successful completions** (`spec.completions=4`), run at most **2 pods
in parallel** (`spec.parallelism=2`), and allow at most **1 retry** on failure
(`spec.backoffLimit=1`).

`kubectl create job` has no flags for `completions`, `parallelism`, or `backoffLimit` - generate
the base manifest with a client-side dry run, edit in the three missing fields, then create the
real object from the edited YAML. Let the Job actually run to completion: the grader waits for
`status.succeeded` to reach `4`.

## Hint

Search kubernetes.io/docs for **"job parallel execution completions"** - the Jobs concept page's
"Parallel Jobs" section documents `spec.completions`, `spec.parallelism`, and `spec.backoffLimit`
together.
