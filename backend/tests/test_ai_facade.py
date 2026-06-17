# tests/test_ai_facade.py
"""The ai.py facade caches one agent instead of rebuilding the genai client per call."""
from app.core import ai


def test_get_agent_caches_single_instance():
    ai.reset_agent_cache()
    try:
        a1 = ai.get_agent()
        a2 = ai.get_agent()
        assert a1 is a2  # built once, reused

        ai.reset_agent_cache()
        a3 = ai.get_agent()
        assert a3 is not a1  # rebuilt after an explicit reset
    finally:
        ai.reset_agent_cache()
