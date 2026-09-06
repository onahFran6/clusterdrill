"""profile_store.py: per-user profile/achievement state. Mocks kube_json's kubectl_get_json/kubectl_apply_json
directly with an in-memory fake, same approach as tests/test_users.py -
this exercises profile_store's own read-modify-write and achievement-
scoping logic against a fake cluster, not kubectl's wire format.
"""
from __future__ import annotations

import profile_store
import pytest
from kube_json import decode_payload


class FakeCluster:
    def __init__(self):
        self.objects: dict[tuple[str, str], dict] = {}

    def get_json(self, *args: str):
        # A get looks like ("configmap", name, "-n", ns) - only the kind and
        # name matter for this in-memory store.
        kind, name = args[0], args[1]
        return self.objects.get((kind, name))

    def apply_json(self, obj: dict) -> bool:
        kind = obj["kind"].lower()
        name = obj["metadata"]["name"]
        self.objects[(kind, name)] = obj
        return True

    def delete(self, *args: str) -> bool:
        # An exact ("configmap", name, "-n", ns) delete, or a label-selector
        # delete ("configmap", "-n", ns, "-l", "key=value") - see
        # delete_profile's two kubectl_delete calls.
        kind = args[0]
        if len(args) >= 2 and not str(args[1]).startswith("-"):
            self.objects.pop((kind, args[1]), None)
            return True
        if "-l" in args:
            key, _, val = args[args.index("-l") + 1].partition("=")
            matches = [
                object_key for object_key, obj in self.objects.items()
                if object_key[0] == kind and obj.get("metadata", {}).get("labels", {}).get(key) == val
            ]
            for object_key in matches:
                self.objects.pop(object_key, None)
        return True


@pytest.fixture
def cluster(monkeypatch):
    fake = FakeCluster()
    monkeypatch.setattr(profile_store, "kubectl_get_json", fake.get_json)
    monkeypatch.setattr(profile_store, "kubectl_apply_json", fake.apply_json)
    monkeypatch.setattr(profile_store, "kubectl_delete", fake.delete)
    return fake


# --- get_profile / _profile_name --------------------------------------------

def test_get_profile_creates_zeroed_defaults_on_first_use(cluster):
    profile = profile_store.get_profile("alice")
    assert profile.spec == profile_store._EMPTY_PROFILE_SPEC
    assert ("configmap", "clusterdrill-profile-alice") in cluster.objects


def test_get_profile_none_user_id_uses_legacy_me_name(cluster):
    profile_store.get_profile(None)
    assert ("configmap", "clusterdrill-profile-me") in cluster.objects
    assert ("configmap", "clusterdrill-profile-None") not in cluster.objects


# --- delete_profile (issue #25 / PLAN.md §4.12's cascade-teardown) ---------

def test_delete_profile_removes_the_profile_configmap(cluster):
    profile_store.get_profile("alice")
    assert ("configmap", "clusterdrill-profile-alice") in cluster.objects

    profile_store.delete_profile("alice")

    assert ("configmap", "clusterdrill-profile-alice") not in cluster.objects


def test_delete_profile_removes_only_that_users_achievements(cluster):
    profile_store.record_check(
        "q1", "topic-a", "domain-a", passed=True, elapsed_ms=500, used_hint=False, user_id="alice",
    )
    profile_store.record_check(
        "q1", "topic-a", "domain-a", passed=True, elapsed_ms=700, used_hint=False, user_id="bob",
    )
    alice_key = ("configmap", "clusterdrill-achievement-no-hints-q1-alice")
    bob_key = ("configmap", "clusterdrill-achievement-no-hints-q1-bob")
    assert alice_key in cluster.objects
    assert bob_key in cluster.objects

    profile_store.delete_profile("alice")

    assert alice_key not in cluster.objects
    assert bob_key in cluster.objects


def test_two_users_get_independent_profiles(cluster):
    profile_store.record_check(
        "q1", "topic-a", "domain-a", passed=True, elapsed_ms=1000, used_hint=False, user_id="alice",
    )
    alice_profile = profile_store.get_profile("alice")
    bob_profile = profile_store.get_profile("bob")

    assert alice_profile.spec["xp"] == profile_store.XP_PER_FIRST_CLEAR
    assert bob_profile.spec["xp"] == 0
    assert "q1" in alice_profile.spec["questions"]
    assert "q1" not in bob_profile.spec["questions"]


# --- record_check / achievement scoping -------------------------------------

def test_record_check_first_clear_awards_xp_and_no_hints_achievement(cluster):
    result = profile_store.record_check(
        "q1", "topic-a", "domain-a", passed=True, elapsed_ms=500, used_hint=False, user_id="alice",
    )
    assert result.first_clear is True
    assert result.profile.spec["xp"] == profile_store.XP_PER_FIRST_CLEAR
    # Also unlocks domain-master here since q1 is the only question ever
    # attempted in domain-a and it passed (100% of questions seen so far) -
    # not the achievement under test, just a side effect of this being the
    # first and only attempt in that domain.
    assert "no-hints-q1" in result.new_achievements
    # The underlying Achievement object's name is scoped per user (so a
    # second user's identical unlock doesn't collide with alice's) even
    # though the returned new_achievements list above stays the plain,
    # display-friendly name.
    assert ("configmap", "clusterdrill-achievement-no-hints-q1-alice") in cluster.objects


def test_two_users_unlocking_the_same_achievement_get_separate_objects(cluster):
    profile_store.record_check(
        "q1", "topic-a", "domain-a", passed=True, elapsed_ms=500, used_hint=False, user_id="alice",
    )
    profile_store.record_check(
        "q1", "topic-a", "domain-a", passed=True, elapsed_ms=700, used_hint=False, user_id="bob",
    )
    assert ("configmap", "clusterdrill-achievement-no-hints-q1-alice") in cluster.objects
    assert ("configmap", "clusterdrill-achievement-no-hints-q1-bob") in cluster.objects
    alice_ach = cluster.objects[("configmap", "clusterdrill-achievement-no-hints-q1-alice")]
    bob_ach = cluster.objects[("configmap", "clusterdrill-achievement-no-hints-q1-bob")]
    assert alice_ach["metadata"]["labels"]["clusterdrill-user"] == "alice"
    assert bob_ach["metadata"]["labels"]["clusterdrill-user"] == "bob"


def test_record_check_without_user_id_uses_unscoped_achievement_name(cluster):
    # Password gate off / no accounts - matches the unscoped naming exactly.
    profile_store.record_check(
        "q1", "topic-a", "domain-a", passed=True, elapsed_ms=500, used_hint=False,
    )
    assert ("configmap", "clusterdrill-achievement-no-hints-q1") in cluster.objects


def test_record_check_repass_does_not_reaward_xp(cluster):
    profile_store.record_check(
        "q1", "topic-a", "domain-a", passed=True, elapsed_ms=1000, used_hint=False, user_id="alice",
    )
    result = profile_store.record_check(
        "q1", "topic-a", "domain-a", passed=True, elapsed_ms=500, used_hint=False, user_id="alice",
    )
    assert result.first_clear is False
    assert result.profile.spec["xp"] == profile_store.XP_PER_FIRST_CLEAR
    assert result.profile.spec["questions"]["q1"]["bestTimeMs"] == 500


# --- record_check speed tier ----------------------------------------

def test_record_check_fast_easy_single_resource_earns_gold(cluster):
    result = profile_store.record_check(
        "q1", "topic-a", "domain-a", passed=True, elapsed_ms=5_000, used_hint=False,
        user_id="alice", difficulty="easy", resource_kind_count=1,
    )
    assert result.speed_tier == "gold"
    assert result.profile.spec["questions"]["q1"]["bestSpeedTier"] == "gold"


def test_record_check_slow_attempt_earns_no_tier(cluster):
    result = profile_store.record_check(
        "q1", "topic-a", "domain-a", passed=True, elapsed_ms=600_000, used_hint=False,
        user_id="alice", difficulty="easy", resource_kind_count=1,
    )
    assert result.speed_tier is None
    assert result.profile.spec["questions"]["q1"].get("bestSpeedTier") is None


def test_record_check_best_speed_tier_reflects_best_ever_run(cluster):
    profile_store.record_check(
        "q1", "topic-a", "domain-a", passed=True, elapsed_ms=5_000, used_hint=False,
        user_id="alice", difficulty="easy", resource_kind_count=1,
    )
    result = profile_store.record_check(
        "q1", "topic-a", "domain-a", passed=True, elapsed_ms=90_000, used_hint=False,
        user_id="alice", difficulty="easy", resource_kind_count=1,
    )
    # This attempt alone is a slower tier (or none)...
    assert result.speed_tier != "gold"
    # ...but bestSpeedTier still reflects the earlier, faster gold-earning run,
    # mirroring how bestTimeMs never regresses on a slower repeat pass.
    assert result.profile.spec["questions"]["q1"]["bestSpeedTier"] == "gold"


def test_record_check_domain_rank_untouched_by_speed_tier(cluster):
    result = profile_store.record_check(
        "q1", "topic-a", "domain-a", passed=True, elapsed_ms=5_000, used_hint=False,
        user_id="alice", difficulty="easy", resource_kind_count=1,
    )
    assert result.profile.spec["domains"]["domain-a"]["rank"] == profile_store._rank_for(1)


# --- boss mini-exam unlock/award ------------------------------------

def test_boss_unlocked_false_before_any_clean_sweep(cluster):
    assert profile_store.boss_unlocked("topic-a", user_id="alice") is False


def test_boss_unlocked_true_after_clean_sweep(cluster):
    profile_store.apply_clean_sweep("topic-a", user_id="alice")
    assert profile_store.boss_unlocked("topic-a", user_id="alice") is True


def test_boss_unlocked_scoped_per_user(cluster):
    profile_store.apply_clean_sweep("topic-a", user_id="alice")
    assert profile_store.boss_unlocked("topic-a", user_id="bob") is False


def test_apply_boss_defeat_creates_scoped_achievement(cluster):
    profile_store.apply_boss_defeat("topic-a", user_id="alice")
    assert ("configmap", "clusterdrill-achievement-boss-topic-a-alice") in cluster.objects
    obj = cluster.objects[("configmap", "clusterdrill-achievement-boss-topic-a-alice")]
    assert decode_payload(obj)["type"] == "boss"


# --- daily/session mixed challenge ----------------------------------

def test_apply_daily_challenge_clear_creates_scoped_achievement(cluster):
    profile_store.apply_daily_challenge_clear("2026-09-03", user_id="alice")
    assert ("configmap", "clusterdrill-achievement-daily-challenge-2026-09-03-alice") in cluster.objects
    obj = cluster.objects[("configmap", "clusterdrill-achievement-daily-challenge-2026-09-03-alice")]
    assert decode_payload(obj)["type"] == "daily-challenge"


def test_apply_daily_challenge_clear_is_one_reward_per_date_not_per_session(cluster):
    # Clearing a second, freshly re-rolled draw the same day re-applies the
    # same deterministic name - still just the one achievement object, not
    # a second one, no matter how many times today's challenge is cleared.
    profile_store.apply_daily_challenge_clear("2026-09-03", user_id="alice")
    profile_store.apply_daily_challenge_clear("2026-09-03", user_id="alice")
    matches = [k for k in cluster.objects if k[0] == "configmap" and "daily-challenge" in k[1]]
    assert matches == [("configmap", "clusterdrill-achievement-daily-challenge-2026-09-03-alice")]


def test_has_achievement_false_before_earned(cluster):
    assert profile_store.has_achievement("daily-challenge-2026-09-03", user_id="alice") is False


# --- record_exam_attempt / apply_clean_sweep --------------------------------

def test_record_exam_attempt_scoped_per_user(cluster):
    profile_store.record_exam_attempt(10, 15, 3600, {"domain-a": 66.0}, user_id="alice")
    alice_profile = profile_store.get_profile("alice")
    bob_profile = profile_store.get_profile("bob")
    assert len(alice_profile.spec["examAttempts"]) == 1
    assert len(bob_profile.spec["examAttempts"]) == 0


def test_apply_clean_sweep_scoped_per_user(cluster):
    profile_store.apply_clean_sweep("topic-a", user_id="alice")
    assert ("configmap", "clusterdrill-achievement-clean-sweep-topic-a-alice") in cluster.objects
