# ADR 0005: Apply exam reference restrictions to every question for the active user

**Status:** Accepted

## Context

Hiding exam navigation links did not remove hint or diagram content from the response, and direct Check requests still invoked grading.
Restricting only selected exam questions would also leave reference material and interim grading available through other question URLs during the same attempt.

## Decision

While a user has an active exam, deny interim Check requests for every question before invoking the grader or recording progress.
Render Task only and omit hints, solutions, discovery paths, diagram data, and the grading panel from every question response for that user.
Preserve question navigation for the selected exam questions and retain the dedicated final submission grader.
Other users' sessions do not affect this policy.

## Consequences

A bookmarked question outside the exam selection remains readable as a task, but cannot expose reference content or live grading until the attempt ends.
The browser no longer receives reference content that it could reveal by switching hidden panels.
This is an application request policy, not isolation from repository files or independently privileged shell access.
Server deadline finalization, and the split between browser logout and the attempt itself, are recorded in [ADR 0006](0006-attempt-lifetime-versus-browser-idle.md).
