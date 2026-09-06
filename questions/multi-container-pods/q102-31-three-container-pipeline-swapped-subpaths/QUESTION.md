# q102-31-three-container-pipeline-swapped-subpaths: Three-stage pipeline pod reads the wrong subPath slice

**Domain:** Application Design and Build · **Points:** 5 · **Namespace:** `q102-31-three-container-pipeline-swapped-subpaths`

A Pod named `pipeline-stages` already exists in this namespace with three
containers - `producer`, `transformer`, and `consumer` - that all mount one
shared `emptyDir` volume named `pipeline-data`, each through its own
`subPath` so every stage only ever sees its own slice of the volume:

- `producer` writes a fixed payload once to `/data/payload.txt`, mounting
  `pipeline-data` at `/data` with `subPath: stage1`.
- `transformer` is supposed to read `producer`'s file at
  `/in/payload.txt` (mounting `pipeline-data` at `/in` with
  `subPath: stage1`), prefix its content with `TRANSFORMED:`, and write
  the result to `/out/payload.txt` (mounting `pipeline-data` at `/out`
  with `subPath: stage2`).
- `consumer` is supposed to read the transformed result at
  `/final/payload.txt`, mounting `pipeline-data` at `/final` with
  `subPath: stage2`.

Whoever wrote the manifest swapped two of the four `volumeMounts[].subPath`
values: `transformer`'s `/in` mount ended up with `subPath: stage2`
(its own write-stage, not `producer`'s stage) and `consumer`'s `/final`
mount ended up with `subPath: stage1` (`producer`'s raw stage, not
`transformer`'s output stage). Nothing crashes and the Pod reports every
container `Running` and `Ready` - `transformer` never sees `producer`'s
file (`/in` now points at the still-empty `stage2` slice) so it never
writes anything, while `consumer` silently reads `producer`'s raw,
untransformed payload straight off `stage1` instead of `transformer`'s
processed output. The pipeline "works" end to end but produces the wrong
final answer.

Fix the Pod so that:

- It still has exactly 3 containers, named `producer`, `transformer`, and
  `consumer` (do not rename them, change their images, or change their
  commands).
- Every `mountPath` stays the same, and `pipeline-data` remains a single
  `emptyDir` volume - only the `subPath` values change:
  - `producer`'s `/data` mount keeps `subPath: stage1`.
  - `transformer`'s `/in` mount is corrected to `subPath: stage1`.
  - `transformer`'s `/out` mount keeps `subPath: stage2`.
  - `consumer`'s `/final` mount is corrected to `subPath: stage2`.
- The Pod reaches `Running` with all three containers ready (3/3).
- `transformer` actually processes `producer`'s data and `consumer`'s
  `/final/payload.txt` ends up containing exactly:

  ```
  TRANSFORMED:batch-payload-4471
  ```

`volumeMounts[].subPath` is immutable on a running Pod, so you cannot
patch it in place - delete and recreate `pipeline-stages` with the
corrected `subPath` values, keeping every other field unchanged.

## Hint

Search kubernetes.io/docs for **"subPath"** - the Volumes concept page's
"Using subPath" section shows how each container in a Pod can mount a
different slice of the same shared volume via `volumeMounts[].subPath`.
