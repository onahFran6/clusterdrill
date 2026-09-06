"""Regression coverage for appliance-visible question paths."""

from services.question_view import appliance_question_text, render_markdown


def test_helm_question_paths_are_rendered_for_the_appliance():
    text = (
        "Use `questions/helm-crds/q110-01-helm-install-release/chart` "
        "(relative to the `practice-bank/` directory)."
    )

    rendered_text = appliance_question_text(text)

    assert "practice-bank/" not in rendered_text
    assert "/opt/clusterdrill/questions/helm-crds/q110-01-helm-install-release/chart" in rendered_text


def test_rendered_question_html_never_exposes_the_monorepo_path():
    html = render_markdown(
        "Run helm install demo questions/helm-crds/q110-01-helm-install-release/chart "
        "(relative to `practice-bank/`)."
    )

    assert "practice-bank/" not in html
    assert "/opt/clusterdrill/questions/helm-crds/q110-01-helm-install-release/chart" in html
