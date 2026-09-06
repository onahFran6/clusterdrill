"""sessions.py: start_fixed/start_randomized/start_mixed, mode_availability,
ActiveSession - against a real QuestionBank (question_bank_factory,
tests/conftest.py) pointed at a tmp_path fixture tree, no mocking needed."""
from __future__ import annotations

from sessions import (
    BOSS_MAX_HP,
    BOSS_SESSION_SIZE,
    BOSS_TIMER_SECONDS,
    DAILY_SESSION_SIZE,
    DAILY_TIMER_SECONDS,
    EXAM_DEFAULT_QUESTION_COUNT,
    EXAM_QUESTION_COUNT_CHOICES,
    SESSION_SIZE,
    TIMER_CHOICES_MINUTES,
    mode_availability,
    start_boss,
    start_daily,
    start_exam,
    start_fixed,
    start_mixed,
    start_randomized,
)


def test_mode_availability_fixed_always_true():
    assert mode_availability(0)["fixed"] is True
    assert mode_availability(1)["fixed"] is True
    assert mode_availability(1000)["fixed"] is True


def test_mode_availability_randomized_gated_on_pool_exceeding_session_size():
    assert mode_availability(SESSION_SIZE)["randomized"] is False
    assert mode_availability(SESSION_SIZE + 1)["randomized"] is True


def test_start_fixed_short_pool_returns_whole_pool(question_bank_factory):
    bank = question_bank_factory({"topic-a": 3})
    session = start_fixed(bank, "topic-a")
    assert session.mode == "fixed"
    assert session.topic == "topic-a"
    assert len(session.question_ids) == 3
    assert len(session) == 3


def test_start_fixed_caps_at_session_size(question_bank_factory):
    bank = question_bank_factory({"topic-a": SESSION_SIZE + 5})
    session = start_fixed(bank, "topic-a")
    assert len(session.question_ids) == SESSION_SIZE


def test_start_fixed_is_deterministic(question_bank_factory):
    bank = question_bank_factory({"topic-a": SESSION_SIZE + 5})
    session_a = start_fixed(bank, "topic-a")
    session_b = start_fixed(bank, "topic-a")
    assert session_a.question_ids == session_b.question_ids


def test_start_randomized_draws_from_pool(question_bank_factory):
    bank = question_bank_factory({"topic-a": SESSION_SIZE + 10})
    session = start_randomized(bank, "topic-a")
    assert len(session.question_ids) == SESSION_SIZE
    assert len(set(session.question_ids)) == SESSION_SIZE  # no duplicates
    pool_ids = {q.id for q in bank.questions if q.topic == "topic-a"}
    assert set(session.question_ids).issubset(pool_ids)


def test_start_mixed_draws_across_topics(question_bank_factory):
    bank = question_bank_factory({"topic-a": 10, "topic-b": 10})
    session = start_mixed(bank)
    assert session.mode == "mixed"
    assert session.topic is None
    assert len(session.question_ids) == SESSION_SIZE
    all_ids = {q.id for q in bank.questions}
    assert set(session.question_ids).issubset(all_ids)


def test_start_fixed_stamps_a_deadline(question_bank_factory):
    bank = question_bank_factory({"topic-a": 3})
    session = start_fixed(bank, "topic-a")
    assert session.timer_enabled is True
    assert session.deadline is not None
    assert session.deadline > session.started_at


def test_start_mixed_uses_the_longer_timer(question_bank_factory):
    from sessions import MIXED_TIMER_SECONDS, TOPIC_TIMER_SECONDS

    bank = question_bank_factory({"topic-a": 20})
    fixed_session = start_fixed(bank, "topic-a")
    mixed_session = start_mixed(bank)
    assert fixed_session.timer_duration_seconds == TOPIC_TIMER_SECONDS
    assert mixed_session.timer_duration_seconds == MIXED_TIMER_SECONDS
    assert MIXED_TIMER_SECONDS > TOPIC_TIMER_SECONDS


def test_active_session_index_of(question_bank_factory):
    bank = question_bank_factory({"topic-a": 3})
    session = start_fixed(bank, "topic-a")
    first_qid = session.question_ids[0]
    assert session.index_of(first_qid) == 0
    assert session.index_of("not-in-session") is None


# --- Difficulty filter (session-setup panel) --------------------------------

def test_start_fixed_difficulty_filter_narrows_the_pool(question_bank_factory):
    bank = question_bank_factory({"topic-a": ["easy", "easy", "medium", "hard", "hard"]})
    session = start_fixed(bank, "topic-a", difficulty="hard")
    assert len(session.question_ids) == 2
    chosen = {bank.get(qid).difficulty for qid in session.question_ids}
    assert chosen == {"hard"}


def test_start_fixed_no_difficulty_filter_is_unchanged(question_bank_factory):
    bank = question_bank_factory({"topic-a": ["easy", "medium", "hard"]})
    session = start_fixed(bank, "topic-a", difficulty=None)
    assert len(session.question_ids) == 3


def test_start_fixed_difficulty_filter_matching_nothing_is_empty(question_bank_factory):
    bank = question_bank_factory({"topic-a": ["easy", "easy"]})
    session = start_fixed(bank, "topic-a", difficulty="hard")
    assert session.question_ids == []


def test_start_randomized_difficulty_filter_narrows_the_pool(question_bank_factory):
    bank = question_bank_factory({"topic-a": ["easy"] * 10 + ["hard"] * (SESSION_SIZE + 5)})
    session = start_randomized(bank, "topic-a", difficulty="hard")
    assert len(session.question_ids) == SESSION_SIZE
    chosen = {bank.get(qid).difficulty for qid in session.question_ids}
    assert chosen == {"hard"}


def test_start_mixed_difficulty_filter_spans_every_topic(question_bank_factory):
    bank = question_bank_factory({
        "topic-a": ["easy", "hard"],
        "topic-b": ["easy", "hard"],
    })
    session = start_mixed(bank, difficulty="hard")
    assert len(session.question_ids) == 2
    chosen = {bank.get(qid).difficulty for qid in session.question_ids}
    assert chosen == {"hard"}


# --- Custom timer (session-setup panel) -------------------------------------

def test_start_fixed_custom_timer_minutes_overrides_the_default(question_bank_factory):
    bank = question_bank_factory({"topic-a": 3})
    session = start_fixed(bank, "topic-a", timer_minutes=30)
    assert session.timer_duration_seconds == 30 * 60


def test_start_fixed_no_timer_minutes_keeps_the_mode_default(question_bank_factory):
    from sessions import TOPIC_TIMER_SECONDS

    bank = question_bank_factory({"topic-a": 3})
    session = start_fixed(bank, "topic-a", timer_minutes=None)
    assert session.timer_duration_seconds == TOPIC_TIMER_SECONDS


def test_start_fixed_out_of_preset_timer_minutes_falls_back_to_default(question_bank_factory):
    from sessions import TOPIC_TIMER_SECONDS

    bank = question_bank_factory({"topic-a": 3})
    # 7 isn't one of TIMER_CHOICES_MINUTES - a forged/stray form value must
    # never buy an arbitrary clock length, only ever "use the default".
    session = start_fixed(bank, "topic-a", timer_minutes=7)
    assert session.timer_duration_seconds == TOPIC_TIMER_SECONDS


def test_start_mixed_custom_timer_minutes_overrides_the_default(question_bank_factory):
    bank = question_bank_factory({"topic-a": 20})
    session = start_mixed(bank, timer_minutes=15)
    assert session.timer_duration_seconds == 15 * 60


# --- Boss mini-exam --------------------------------------------

def test_start_boss_draws_fixed_size_from_one_topic(question_bank_factory):
    bank = question_bank_factory({"topic-a": 20, "topic-b": 20})
    session = start_boss(bank, "topic-a")
    assert session.mode == "boss"
    assert session.topic == "topic-a"
    assert len(session.question_ids) == BOSS_SESSION_SIZE
    assert len(set(session.question_ids)) == BOSS_SESSION_SIZE
    pool_ids = {q.id for q in bank.questions if q.topic == "topic-a"}
    assert set(session.question_ids).issubset(pool_ids)


def test_start_boss_short_pool_returns_whole_pool(question_bank_factory):
    bank = question_bank_factory({"topic-a": 3})
    session = start_boss(bank, "topic-a")
    assert len(session.question_ids) == 3


def test_start_boss_starts_at_full_hp_with_its_own_timer(question_bank_factory):
    bank = question_bank_factory({"topic-a": 20})
    session = start_boss(bank, "topic-a")
    assert session.hp == BOSS_MAX_HP
    assert session.timer_enabled is True
    assert session.timer_duration_seconds == BOSS_TIMER_SECONDS
    assert session.deadline is not None


# --- Daily/session mixed challenge ----------------------------

def test_start_daily_draws_across_topics(question_bank_factory):
    # Distinct first letters ("alpha"/"beta") - question_bank_factory
    # derives each qid's prefix from only the topic name's first letter
    # (tests/conftest.py), so "topic-a"/"topic-b" would collide on qid and
    # break this test's uniqueness assertion below for a fixture reason
    # unrelated to start_daily itself.
    bank = question_bank_factory({"alpha-topic": 10, "beta-topic": 10})
    session = start_daily(bank)
    assert session.mode == "daily"
    assert session.topic is None
    assert len(session.question_ids) == DAILY_SESSION_SIZE
    assert len(set(session.question_ids)) == DAILY_SESSION_SIZE
    all_ids = {q.id for q in bank.questions}
    assert set(session.question_ids).issubset(all_ids)


def test_start_daily_short_pool_returns_whole_pool(question_bank_factory):
    bank = question_bank_factory({"topic-a": 3})
    session = start_daily(bank)
    assert len(session.question_ids) == 3


def test_start_daily_has_its_own_timer(question_bank_factory):
    bank = question_bank_factory({"topic-a": 20})
    session = start_daily(bank)
    assert session.timer_enabled is True
    assert session.timer_duration_seconds == DAILY_TIMER_SECONDS
    assert session.deadline is not None


def test_start_daily_is_freshly_shuffled_each_call(question_bank_factory):
    # Not a hard guarantee (a shuffle can coincidentally repeat), but with
    # a large-enough pool this is deterministic-enough evidence that this
    # isn't secretly deterministic like start_fixed.
    bank = question_bank_factory({"topic-a": 40})
    draws = {tuple(start_daily(bank).question_ids) for _ in range(10)}
    assert len(draws) > 1


# --- True exam-condition mock exam -------------------

def test_start_exam_defaults_draw_across_all_topics_at_the_default_size(question_bank_factory):
    bank = question_bank_factory({"topic-a": 20, "topic-b": 20})
    session = start_exam(bank)
    assert session.mode == "exam"
    assert session.topic is None
    assert len(session.question_ids) == EXAM_DEFAULT_QUESTION_COUNT
    all_ids = {q.id for q in bank.questions}
    assert set(session.question_ids).issubset(all_ids)


def test_start_exam_topics_filter_narrows_the_pool(question_bank_factory):
    bank = question_bank_factory({"alpha-topic": 20, "beta-topic": 20})
    session = start_exam(bank, topics=["alpha-topic"], question_count=20)
    assert len(session.question_ids) == 20
    chosen_topics = {bank.get(qid).topic for qid in session.question_ids}
    assert chosen_topics == {"alpha-topic"}


def test_start_exam_empty_topics_list_is_treated_as_all(question_bank_factory):
    bank = question_bank_factory({"alpha-topic": 10, "beta-topic": 10})
    session = start_exam(bank, topics=[], question_count=20)
    chosen_topics = {bank.get(qid).topic for qid in session.question_ids}
    assert chosen_topics == {"alpha-topic", "beta-topic"}


def test_start_exam_difficulty_mix_filters_to_the_selected_set(question_bank_factory):
    bank = question_bank_factory({"topic-a": ["easy", "medium", "hard"] * 5})
    session = start_exam(bank, difficulties=["easy", "hard"], question_count=20)
    chosen = {bank.get(qid).difficulty for qid in session.question_ids}
    assert chosen == {"easy", "hard"}


def test_start_exam_empty_difficulties_list_is_treated_as_all(question_bank_factory):
    bank = question_bank_factory({"topic-a": ["easy", "medium", "hard"] * 5})
    session = start_exam(bank, difficulties=[], question_count=20)
    chosen = {bank.get(qid).difficulty for qid in session.question_ids}
    assert chosen == {"easy", "medium", "hard"}


def test_start_exam_question_count_choices_are_all_honored(question_bank_factory):
    bank = question_bank_factory({"topic-a": 25})
    for count in EXAM_QUESTION_COUNT_CHOICES:
        session = start_exam(bank, question_count=count)
        assert len(session.question_ids) == count


def test_start_exam_out_of_preset_question_count_falls_back_to_default(question_bank_factory):
    bank = question_bank_factory({"topic-a": 25})
    session = start_exam(bank, question_count=7)  # not one of EXAM_QUESTION_COUNT_CHOICES
    assert len(session.question_ids) == EXAM_DEFAULT_QUESTION_COUNT


def test_start_exam_short_pool_returns_whole_pool(question_bank_factory):
    bank = question_bank_factory({"topic-a": 3})
    session = start_exam(bank, question_count=20)
    assert len(session.question_ids) == 3


def test_start_exam_custom_timer_minutes_overrides_the_default(question_bank_factory):
    bank = question_bank_factory({"topic-a": 20})
    session = start_exam(bank, question_count=15, timer_minutes=30)
    assert session.timer_duration_seconds == 30 * 60


def test_start_exam_out_of_preset_timer_falls_back_to_the_computed_default(question_bank_factory):
    bank = question_bank_factory({"topic-a": 20})
    # 7 isn't one of TIMER_CHOICES_MINUTES.
    session = start_exam(bank, question_count=15, timer_minutes=7)
    assert session.timer_duration_seconds == 120 * 60


def test_start_exam_default_timer_targets_about_8_minutes_per_question(question_bank_factory):
    from sessions import default_exam_timer_minutes

    # 8 min/question -> 40/80/120/160; nearest TIMER_CHOICES_MINUTES preset
    # ([15, 30, 45, 60, 90, 120]) to each.
    assert default_exam_timer_minutes(5) == 45
    assert default_exam_timer_minutes(10) == 90
    assert default_exam_timer_minutes(15) == 120
    assert default_exam_timer_minutes(20) == 120
    for count in EXAM_QUESTION_COUNT_CHOICES:
        assert default_exam_timer_minutes(count) in TIMER_CHOICES_MINUTES


def test_start_exam_is_freshly_shuffled_each_call(question_bank_factory):
    bank = question_bank_factory({"topic-a": 40})
    draws = {tuple(start_exam(bank, question_count=20).question_ids) for _ in range(10)}
    assert len(draws) > 1


def test_filter_by_difficulty_accepts_an_iterable_directly(question_bank_factory):
    from sessions import _filter_by_difficulty

    bank = question_bank_factory({"topic-a": ["easy", "medium", "hard"]})
    filtered = _filter_by_difficulty(bank.questions, ["easy", "hard"])
    assert {q.difficulty for q in filtered} == {"easy", "hard"}
