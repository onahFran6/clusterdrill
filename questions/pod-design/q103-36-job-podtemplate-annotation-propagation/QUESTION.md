# q103-36: Tag every pod a Job creates with a build-id annotation

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q103-36-job-podtemplate-annotation-propagation`

A Job named `metadata-tagger` already exists in namespace
`q103-36-job-podtemplate-annotation-propagation`. Every pod it creates must carry the annotation
`pipeline.example.com/build-id: "2026-09"`. The pod template does not have that annotation.

`.spec.template` is immutable. Delete `metadata-tagger` and recreate it with that annotation on
`.spec.template.metadata.annotations`. Keep the same name, image (`busybox:1.36`), and command
(`echo tagged`).

Once recreated, the Job must complete successfully, and the pod it creates must carry the same
annotation.

## Hint

Search kubernetes.io/docs for **"pod template metadata"** - the Jobs concept page's "Pod Template"
section explains that a Job's `.spec.template.metadata` (labels and annotations) is copied onto
every pod it creates.
