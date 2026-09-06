"""Health check route - extracted from app.py's original monolith (2026-08
restructure) with no behavior change, just a new home."""
from __future__ import annotations

from fastapi import APIRouter

from questions import bank

router = APIRouter()


@router.get("/healthz")
def healthz():
    bank.refresh()
    return {"ok": True, "question_count": len(bank), "excluded_question_count": bank.excluded_count}
