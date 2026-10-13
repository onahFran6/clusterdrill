# ADR 0006: Keep practice and exam attempts across browser idle logout

**Status:** Accepted

## Context

The idle watchdog exists to drop an unattended authenticated browser session.
It used to clear every in-memory attempt at the same time as it revoked logins and killed embedded tmux sessions.
Work in an external terminal produces neither browser events nor terminal WebSocket frames, so that cleanup could discard a still-active attempt while the learner was using the cluster.
Exam deadlines are stamped on the server, but submission used to run only from the open browser.

The session store is process memory. Durable recovery across a restart is a separate problem.
The idle clock is still one clock for the whole process, including experimental account mode.

## Decision

Browser idle expiry revokes login sessions and stops embedded terminals.
It does not delete the active practice or exam attempt, pause or extend an exam deadline, or revoke SSH and Kubernetes credentials the learner holds outside the app.

Manual Submit Exam and the server deadline scheduler share `session_lifecycle.finalize_exam()`.
That function grades each selected question at most once, records one result, and cleans up the attempt.
A repeated submit for the same attempt returns the stored result.
An expired exam follows that path even when the browser is closed.
After the learner signs in again, an unexpired attempt resumes at its last question. A finalized exam opens its result.

Local display preferences stay in `localStorage` under `clusterdrill-workspace-v2`.
They are shared by tabs and accounts on the same browser origin, and changing them does not touch session lifetime.

## Consequences

An authenticated learner can keep working from their own terminal past the idle warning, then sign in again and continue the same attempt, until the exam deadline or a process restart.
Grading at the deadline sees cluster state at finalization time. It cannot reconstruct the cluster as it was at an earlier instant if something changed afterward.
A restart still drops in-memory attempts and results.
Experimental accounts share the same idle action until a per-user idle clock exists. This decision does not add that clock, and it does not make path separation into tenant isolation.
Idle expiry still does not kill the terminal or revoke anything the learner holds outside the app - that is unchanged.
Finalization itself now kills that attempt's terminal outright, once grading has actually begun: see [ADR 0010](0010-revoke-rbac-at-exam-finalization.md).
