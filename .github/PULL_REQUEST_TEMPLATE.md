## Summary

<!-- What does this PR change, and why? -->

## Licensing boundary check

This repo mixes MIT-original content with GPL-3.0-ported content, isolated in `questions/community/`.

- [ ] I confirm this PR does **not** mix MIT and GPL-3.0 content in the same question folder.
- [ ] If this PR touches `questions/community/` (GPL-3.0), it touches **only** that directory and carries no MIT-licensed content into it.
- [ ] If this PR touches any other question directory (MIT), it does **not** copy, port, or adapt content from `questions/community/` or any other GPL-3.0 source.

## Verification

<!-- For question changes, paste the output of: lib/verify-question.sh <question> -->
<!-- For web-app changes, paste the output of: web/.venv/bin/pytest web/tests -->

- [ ] Ran the relevant verification command(s) above and they pass.

## Checklist

- [ ] I've read the [Licensing section of the README](../README.md#licensing).
- [ ] New/changed questions follow the existing folder shape (`setup.sh`, `check.sh`, etc.) and `check.sh` only queries live cluster state.
