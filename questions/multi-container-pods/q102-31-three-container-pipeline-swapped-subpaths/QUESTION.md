# q102-31: Fix a three-stage pipeline that yields the wrong final payload

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q102-31-three-container-pipeline-swapped-subpaths`

A Pod named `pipeline-stages` already exists in this namespace with three
containers - `producer`, `transformer`, and `consumer` - that all mount one
shared `emptyDir` volume named `pipeline-data`, each through its own `subPath`
so every stage only sees its own slice of the volume:

- `producer` writes a fixed payload once to `/data/payload.txt`, mounting
  `pipeline-data` at `/data` with `subPath: stage1`.
- `transformer` should read `producer`'s file at `/in/payload.txt` (mounting
  `pipeline-data` at `/in` with `subPath: stage1`), prefix its content with
  `TRANSFORMED:`, and write the result to `/out/payload.txt` (mounting
  `pipeline-data` at `/out` with `subPath: stage2`).
- `consumer` should read the transformed result at `/final/payload.txt`,
  mounting `pipeline-data` at `/final` with `subPath: stage2`.

Nothing crashes and the Pod reports every container `Running` and `Ready`, but
`consumer`'s `/final/payload.txt` does not contain the transformed payload.

Fix the Pod so that:

- It still has exactly 3 containers, named `producer`, `transformer`, and
  `consumer` (do not rename them, change their images, or change their
  commands).
- Every `mountPath` stays the same, and `pipeline-data` remains a single
  `emptyDir` volume - only the `subPath` values change:
  - `producer`'s `/data` mount keeps `subPath: stage1`.
  - `transformer`'s `/in` mount uses `subPath: stage1`.
  - `transformer`'s `/out` mount keeps `subPath: stage2`.
  - `consumer`'s `/final` mount uses `subPath: stage2`.
- The Pod reaches `Running` with all three containers ready (3/3).
- `consumer`'s `/final/payload.txt` ends up containing exactly:

  ```
  TRANSFORMED:batch-payload-4471
  ```

`volumeMounts[].subPath` is immutable on a running Pod - delete and recreate
`pipeline-stages` with the corrected `subPath` values, keeping every other
field unchanged.

## Hint

Search kubernetes.io/docs for **"subPath"** - the Volumes concept page's
"Using subPath" section shows how each container in a Pod can mount a
different slice of the same shared volume via `volumeMounts[].subPath`.
Compare each stage's `subPath` to the intended read/write slice.
