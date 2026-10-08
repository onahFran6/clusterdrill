# q118-02: Render six pieces of work

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q118-02-completions-and-parallelism`

Team Venus needs *Job* `render` to succeed **6** times, with at most **2** Pods working at once.
Use `busybox:1.36` running `sh -c 'echo rendering on $(hostname); sleep 5'`.
Watch the Running Pod count during execution (practice observation, ungraded).
Finish with six successful Pods and confirm their total count.

## Hint

Search kubernetes.io/docs for "parallel execution for Jobs" and the distinction between successful completions and concurrent Pods.
