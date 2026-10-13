# ADR 0007: Separate public topics from question source folders

Status: Accepted

## Context

Versioned question collections split the same subject across multiple practice topics.
Moving source directories would also change content paths referenced by tooling and documentation.

## Decision

Map source folder names to canonical public topics during question discovery.
Keep question IDs, metadata, and source paths intact, and keep community content separate.
Normalize old topic names at session entry points and redirect old topic detail URLs.

## Consequences

Practice, mock exams, and progress share the combined question pools.
Existing question progress remains attached to the same IDs.
Topic-specific achievements earned under old names remain historical and are not migrated to unlock the enlarged pools.
