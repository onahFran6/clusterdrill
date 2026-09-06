# q103-36: Tag every pod a Job creates with a build-id annotation

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-36-job-podtemplate-annotation-propagation`

`setup.sh` already created a Job named `metadata-tagger` in namespace
`q103-36-job-podtemplate-annotation-propagation`. Your release pipeline needs every pod this Job
creates to be traceable back to the build that produced it, but nothing on the Job's pod template
records that today.

A Job's pod template metadata (`.spec.template.metadata`) is what actually gets copied onto every
pod the Job creates - it works the same way for annotations as it does for labels. `.spec.template`
is immutable once the Job exists, so delete `metadata-tagger` and recreate it with an annotation
`pipeline.example.com/build-id: "2026-09"` added to `.spec.template.metadata.annotations`. Keep the
same name, image (`busybox:1.36`), and command (`echo tagged`).

Once recreated, the Job must complete successfully, and the pod it creates must itself carry that
same annotation.

## Hint

Search kubernetes.io/docs for **"pod template metadata"** - the Jobs concept page's "Pod Template"
section explains that a Job's `.spec.template.metadata` (both labels and annotations) is copied
onto every pod it creates.
