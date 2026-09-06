"""Reads/writes the per-user profile and achievement state that
backs the app's progress tracking - "store progress as Kubernetes objects,
not database rows." This module owns the only code
path that talks to that state - a plain `kubectl get/apply` from here, not
a reconciliation loop.

Stored as ConfigMaps in kube_json.SYSTEM_NAMESPACE, not as instances of a
project-owned CustomResourceDefinition: no domain is confirmed for a
project-owned CRD group (see practice-bank/docs/adr/0001-naming-standard.md),
so this data lives under kube_json.configmap_payload's generic JSON-blob
shape instead of a typed CRD schema. Functionally the same idea -
Kubernetes objects, not database rows - just without a custom API type.

Kept strictly additive: nothing here ever
feeds back into grading truth. This module is only ever called *after*
grading_client.run_check() has already produced a real pass/fail result from
the live cluster - it never invents its own notion of "passed".

Originally single-tenant -
exactly one profile object, named "me". Every function here now takes an
optional `user_id`, and reads/writes that user's own profile object instead
- `user_id=None` (password gate off, no accounts) still resolves to the
"me" name, the exact prior behavior. Achievement object names get the same
per-user scoping (`f"{name}-{user_id}"`, see _scoped below) - an
achievement's object name must be deterministic and unique per unlock
(apply_achievement's own docstring), and two different users both first-
clearing the same question with no hints must produce two distinct
achievement objects, not the second user's unlock silently updating the
first user's object in place. Both kinds live in kube_json.SYSTEM_NAMESPACE
(never in a question's own qNNN namespace) so a question's own Restart
(full_reset deleting that question's namespace) can never delete
profile/achievement state.
"""
from __future__ import annotations

import copy
import re
import threading
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone

from kube_json import (
    SYSTEM_NAMESPACE,
    configmap_payload,
    decode_payload,
    kubectl_apply_json,
    kubectl_delete,
    kubectl_get_json,
)

PROFILE_NAME = "me"
_PROFILE_LABELS = {"clusterdrill-kind": "profile"}
_ACHIEVEMENT_LABELS = {"clusterdrill-kind": "achievement"}

# XP awarded the first time a question is fully passed. Re-passing an
# already-solved question (e.g. after a deliberate Restart) still updates
# personal-best time but doesn't re-award XP - otherwise XP farming via
# repeated Check/Restart would be trivial.
XP_PER_FIRST_CLEAR = 10

# Bronze/Silver/Gold speed tiers per question
# (thresholds tuned per topic - a one-liner imperative command earns Gold
# faster than a multi-resource YAML task). This is a *different* Bronze/
# Silver/Gold from _RANK_THRESHOLDS below - that one is a per-domain rank
# derived from cumulative correct-count; this one is a per-question badge
# derived from one attempt's time-to-correct. Per-question thresholds are
# computed, not hand-authored per question (500+ questions across the
# bank) - `difficulty` and `resource_kinds` are already on every question's
# domains.fragment.yaml entry (needed for grading/display anyway), and
# resource-kind count is a reasonable proxy for "one-liner vs multi-resource
# YAML task": a Service+Ingress+NetworkPolicy question legitimately takes
# longer to type than a single kubectl run command, independent of how hard
# the underlying concept is.
_SPEED_TIER_BASE_GOLD_SECONDS = {"easy": 20, "medium": 45, "hard": 90}
_SPEED_TIER_DEFAULT_GOLD_SECONDS = 45  # unknown/missing difficulty
_SPEED_TIER_SECONDS_PER_EXTRA_RESOURCE_KIND = 15
# Silver/Bronze are multiples of Gold, not independently tuned - keeps the
# three tiers proportionate as the Gold baseline above gets retuned per
# difficulty/topic over time, rather than three numbers to keep in sync.
_SPEED_TIER_SILVER_MULTIPLIER = 2.5
_SPEED_TIER_BRONZE_MULTIPLIER = 5.0


def _speed_tier_thresholds_ms(difficulty: str | None, resource_kind_count: int) -> tuple[int, int, int]:
    """Returns (gold_ms, silver_ms, bronze_ms) - an elapsed time at or under
    gold_ms earns Gold, at or under silver_ms earns Silver, at or under
    bronze_ms earns Bronze, above bronze_ms earns no tier."""
    base_gold = _SPEED_TIER_BASE_GOLD_SECONDS.get(difficulty, _SPEED_TIER_DEFAULT_GOLD_SECONDS)
    extra_kinds = max(0, (resource_kind_count or 1) - 1)
    gold_seconds = base_gold + extra_kinds * _SPEED_TIER_SECONDS_PER_EXTRA_RESOURCE_KIND
    gold_ms = gold_seconds * 1000
    silver_ms = int(gold_ms * _SPEED_TIER_SILVER_MULTIPLIER)
    bronze_ms = int(gold_ms * _SPEED_TIER_BRONZE_MULTIPLIER)
    return gold_ms, silver_ms, bronze_ms


def _speed_tier_for(elapsed_ms: int, difficulty: str | None, resource_kind_count: int) -> str | None:
    gold_ms, silver_ms, bronze_ms = _speed_tier_thresholds_ms(difficulty, resource_kind_count)
    if elapsed_ms <= gold_ms:
        return "gold"
    if elapsed_ms <= silver_ms:
        return "silver"
    if elapsed_ms <= bronze_ms:
        return "bronze"
    return None

# threading.RLock, not asyncio.Lock: FastAPI's sync `def` routes run in a
# threadpool (Starlette's run_in_threadpool), so concurrent requests really
# can race on this module's read-modify-write kubectl calls even though the
# app is single-user. Reentrant specifically because record_check()/
# record_exam_attempt() hold the lock while calling get_profile(), which
# itself takes the lock on the first-ever call (profile doesn't exist yet) -
# a plain Lock would deadlock a single thread against itself there.
_lock = threading.RLock()

_EMPTY_PROFILE_SPEC: dict = {
    "xp": 0,
    "questionsAnswered": 0,
    "correctCount": 0,
    "streakDays": 0,
    "lastActiveDate": "",
    "dailyActivity": {},
    "domains": {},
    "questions": {},
    "examAttempts": [],
}


def _slugify(value: str) -> str:
    slug = re.sub(r"[^a-z0-9]+", "-", value.lower()).strip("-")
    return slug or "unknown"


def _profile_name(user_id: str | None) -> str:
    return user_id if user_id else PROFILE_NAME


def _scoped(name: str, user_id: str | None) -> str:
    """An achievement object's name, scoped to the owning user - see this
    module's docstring for why two users' identical unlocks must not share
    one object. Unscoped (unchanged) when user_id is None."""
    return f"{name}-{user_id}" if user_id else name


def _profile_object_name(user_id: str | None) -> str:
    return f"clusterdrill-profile-{_profile_name(user_id)}"


def _achievement_object_name(scoped_name: str) -> str:
    return f"clusterdrill-achievement-{scoped_name}"


@dataclass
class Profile:
    spec: dict


def _save_profile(spec: dict, user_id: str | None = None) -> Profile:
    kubectl_apply_json(configmap_payload(_profile_object_name(user_id), spec, labels=_PROFILE_LABELS))
    return Profile(spec=spec)


def get_profile(user_id: str | None = None) -> Profile:
    """Reads this user's profile, creating it with zeroed defaults on first
    use. user_id=None reads/creates the "me" profile (password gate off,
    no accounts)."""
    name = _profile_object_name(user_id)
    obj = kubectl_get_json("configmap", name, "-n", SYSTEM_NAMESPACE)
    if obj is None:
        with _lock:
            # Re-check inside the lock in case another request just created it.
            obj = kubectl_get_json("configmap", name, "-n", SYSTEM_NAMESPACE)
            if obj is None:
                return _save_profile(copy.deepcopy(_EMPTY_PROFILE_SPEC), user_id)
    spec = copy.deepcopy(_EMPTY_PROFILE_SPEC)
    spec.update(decode_payload(obj) or {})
    return Profile(spec=spec)


def delete_profile(user_id: str) -> None:
    """Removes this user's Profile ConfigMap and every achievement
    ConfigMap scoped to them (see apply_achievement's clusterdrill-user
    label below) - called when an admin deletes an account
    (routers/admin_router.py), per PLAN.md §4.12's cascade-teardown
    requirement, so a deleted user's progress/achievement state doesn't sit
    in the cluster forever with no owner. user_id is required, unlike every
    read/write function above - the "me" profile (password gate off, no
    accounts) has no admin delete-user flow to call this from.
    """
    kubectl_delete("configmap", _profile_object_name(user_id), "-n", SYSTEM_NAMESPACE)
    kubectl_delete("configmap", "-n", SYSTEM_NAMESPACE, "-l", f"clusterdrill-user={user_id}")


def apply_achievement(name: str, achievement_type: str, question_id: str | None = None,
                       topic: str | None = None, user_id: str | None = None) -> None:
    """Applies one achievement object. `name` must be deterministic per
    unlock (e.g. f"no-hints-{qid}") so re-applying the same unlock is a
    no-op update, not a duplicate - this module never needs to check "have I
    already earned this" before calling apply_achievement. Scoped to
    user_id (see _scoped) so two different users' identical unlocks don't
    collide on one shared object.
    """
    labels = dict(_ACHIEVEMENT_LABELS)
    if question_id:
        labels["clusterdrill-question"] = question_id
    if user_id:
        labels["clusterdrill-user"] = user_id
    spec = {
        "type": achievement_type,
        "earnedAt": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    }
    if question_id:
        spec["questionId"] = question_id
    if topic:
        spec["topic"] = topic
    obj = configmap_payload(_achievement_object_name(_scoped(name, user_id)), spec, labels=labels)
    kubectl_apply_json(obj)


@dataclass
class CheckRecordResult:
    profile: Profile
    first_clear: bool
    new_achievements: list[str]
    speed_tier: str | None = None


def record_check(qid: str, topic: str, domain: str | None, passed: bool,
                  elapsed_ms: int | None, used_hint: bool, user_id: str | None = None,
                  difficulty: str | None = None, resource_kind_count: int = 1) -> CheckRecordResult:
    """Records the outcome of one Check call, pass or fail. `passed` here
    means "fully passed" (grading's passed == total), decided by the caller
    - this function never reinterprets a partial score as a pass.
    """
    new_achievements: list[str] = []
    with _lock:
        profile = get_profile(user_id)
        spec = profile.spec

        q = dict(spec["questions"].get(
            qid, {"passed": False, "bestTimeMs": None, "attempts": 0, "usedHint": False, "domain": domain}
        ))
        q["attempts"] = q.get("attempts", 0) + 1
        q["domain"] = domain  # unconditional: a failed attempt still needs to be
                               # attributable to a domain for the mastery check below.
        if used_hint:
            # Unconditional too, same reasoning as `domain` above - a failed
            # check where the hint was already open is still a real fact
            # about this attempt, not something to only record once it
            # eventually passes. The no-hints achievement itself never reads
            # this stored field (it decides off the fresh `used_hint`
            # parameter for the exact passing call, see below), so this is
            # purely about keeping the stored record honest for anything
            # else that might read it (e.g. a future per-question detail
            # view) - not a correctness dependency for the achievement.
            q["usedHint"] = True
        was_passed_before = bool(q.get("passed"))
        first_clear = passed and not was_passed_before

        speed_tier: str | None = None
        if passed:
            q["passed"] = True
            if elapsed_ms is not None:
                speed_tier = _speed_tier_for(elapsed_ms, difficulty, resource_kind_count)
                best = q.get("bestTimeMs")
                q["bestTimeMs"] = elapsed_ms if best is None else min(best, elapsed_ms)
                q["bestSpeedTier"] = _speed_tier_for(q["bestTimeMs"], difficulty, resource_kind_count)
        spec["questions"][qid] = q

        if domain:
            # "correct" only counts first-clear passes (matches
            # correctCount's semantics elsewhere); "answered" counts every
            # distinct question ever attempted in this domain, pass or
            # fail, so a still-failing sibling question correctly holds
            # answered > correct and blocks domain-master below.
            d = dict(spec["domains"].get(domain, {"answered": 0, "correct": 0}))
            if q["attempts"] == 1:
                d["answered"] = d.get("answered", 0) + 1
            d["correct"] = d.get("correct", 0) + (1 if first_clear else 0)
            d["rank"] = _rank_for(d["correct"])
            spec["domains"][domain] = d

        if first_clear:
            spec["questionsAnswered"] = spec.get("questionsAnswered", 0) + 1
            spec["correctCount"] = spec.get("correctCount", 0) + 1
            spec["xp"] = spec.get("xp", 0) + XP_PER_FIRST_CLEAR

            today = datetime.now(timezone.utc).date()
            today_str = today.isoformat()
            spec["dailyActivity"][today_str] = spec["dailyActivity"].get(today_str, 0) + 1
            last_active = spec.get("lastActiveDate") or ""
            if last_active != today_str:
                if last_active == (today - timedelta(days=1)).isoformat():
                    spec["streakDays"] = spec.get("streakDays", 0) + 1
                else:
                    spec["streakDays"] = 1
                spec["lastActiveDate"] = today_str

            if not used_hint:
                new_achievements.append(("no-hints-" + qid, "no-hints", qid, topic))

            if domain and d["answered"] > 0 and d["answered"] == d["correct"]:
                # "100% on every question seen so far".
                new_achievements.append(
                    ("domain-master-" + _slugify(domain), "domain-master", None, topic)
                )

        profile = _save_profile(spec, user_id)

    for name, atype, qid_for_ach, topic_for_ach in new_achievements:
        apply_achievement(name, atype, question_id=qid_for_ach, topic=topic_for_ach, user_id=user_id)

    return CheckRecordResult(profile=profile, first_clear=first_clear,
                              new_achievements=[n for n, *_ in new_achievements],
                              speed_tier=speed_tier)


def apply_clean_sweep(topic: str, user_id: str | None = None) -> None:
    apply_achievement(f"clean-sweep-{_slugify(topic)}", "clean-sweep", topic=topic, user_id=user_id)


def has_achievement(name: str, user_id: str | None = None) -> bool:
    """Whether the (deterministically-named, see apply_achievement) unlock
    `name` has ever been earned by this user - a plain existence check
    against the single named achievement object, not a list/query, since
    every achievement name in this module is already computed
    deterministically from what it represents (e.g. f"clean-sweep-{slug}")."""
    name = _achievement_object_name(_scoped(name, user_id))
    return kubectl_get_json("configmap", name, "-n", SYSTEM_NAMESPACE) is not None


def boss_unlocked(topic: str, user_id: str | None = None) -> bool:
    """A topic's boss mini-exam unlocks the moment its clean-sweep
    achievement has ever been earned - "clearing every question in a topic
    lab's current session" is exactly what
    clean-sweep already means (see apply_clean_sweep), so this reuses that
    existing achievement as the unlock state instead of tracking a second,
    redundant "have I cleared this topic" flag anywhere."""
    return has_achievement(f"clean-sweep-{_slugify(topic)}", user_id=user_id)


def apply_boss_defeat(topic: str, user_id: str | None = None) -> None:
    apply_achievement(f"boss-{_slugify(topic)}", "boss", topic=topic, user_id=user_id)


def apply_daily_challenge_clear(date_str: str, user_id: str | None = None) -> None:
    """The deterministic name is keyed on the calendar date
    (`date_str`, caller-supplied so this stays a pure function - see
    routers/questions_router.py's call site), not on which specific 5
    question ids were drawn - clearing a second, freshly re-rolled daily
    challenge later the same day is still just the same day's one reward,
    same idempotent-reapply reasoning as every other apply_* here."""
    apply_achievement(f"daily-challenge-{date_str}", "daily-challenge", user_id=user_id)


def record_exam_attempt(score: int, total: int, duration_sec: int,
                         domain_breakdown: dict[str, float], user_id: str | None = None) -> Profile:
    with _lock:
        profile = get_profile(user_id)
        spec = profile.spec
        spec["examAttempts"] = spec.get("examAttempts", []) + [{
            "date": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
            "score": score,
            "total": total,
            "durationSec": duration_sec,
            "domainBreakdown": domain_breakdown,
        }]
        return _save_profile(spec, user_id)


_RANK_THRESHOLDS = [
    (1, "bronze"),
    (10, "silver"),
    (25, "gold"),
    (50, "platinum"),
]


def _rank_for(correct_count: int) -> str:
    rank = "unranked"
    for threshold, name in _RANK_THRESHOLDS:
        if correct_count >= threshold:
            rank = name
    return rank
