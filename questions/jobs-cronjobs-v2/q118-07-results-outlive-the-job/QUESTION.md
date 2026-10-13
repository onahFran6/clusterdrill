# q118-07: Keep calculation results after cleanup

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q118-07-results-outlive-the-job`

Team Uranus needs *Job* `calc` using `busybox:1.36` to write `total=$((6*7))` into `/results/latest.txt` on *PVC* `results` (**100Mi**, default StorageClass, `ReadWriteOnce`).
The Job and its Pods must be cleaned up automatically **30 seconds** after completion.
After the Job disappears, create *Pod* `dashboard` using `busybox:1.36` to mount the same claim and print the file.
Keep the completed dashboard Pod so its log can be graded.

## Hint

Search kubernetes.io/docs for "persistent volumes" and "TTL controller for finished resources".
