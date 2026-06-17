# tests/test_brevo_email.py
"""Brevo 4.x migration smoke tests.

Actual delivery can't be verified without a live API key + network, so these
mock the Brevo client and assert (a) each helper calls send_transac_email with
the right keyword fields on the new SDK, and (b) a send failure is swallowed and
logged rather than propagated (these are fire-and-forget notifications).
"""
import logging
from unittest.mock import MagicMock

import app.core.email.brevo as be


def _spy_client(monkeypatch):
    sent = MagicMock()
    fake_client = MagicMock()
    fake_client.transactional_emails.send_transac_email = sent
    monkeypatch.setattr(be.brevo, "Brevo", MagicMock(return_value=fake_client))
    return sent


def test_reset_code_email_calls_sdk(monkeypatch):
    sent = _spy_client(monkeypatch)
    be.send_reset_code_email("u@x.com", "123456")
    sent.assert_called_once()
    kwargs = sent.call_args.kwargs
    assert kwargs["to"][0].email == "u@x.com"
    assert kwargs["params"] == {"RESET_CODE": "123456"}
    assert "template_id" in kwargs


def test_signup_token_email_calls_sdk(monkeypatch):
    sent = _spy_client(monkeypatch)
    be.send_signup_token_email("u@x.com", "tok123")
    kwargs = sent.call_args.kwargs
    assert kwargs["to"][0].email == "u@x.com"
    assert "VERIFICATION_LINK" in kwargs["params"]
    assert "tok123" in kwargs["params"]["VERIFICATION_LINK"]


def test_html_email_sets_sender_subject_content(monkeypatch):
    sent = _spy_client(monkeypatch)
    be.send_html_email("u@x.com", "Subject", "<p>hi</p>")
    kwargs = sent.call_args.kwargs
    assert kwargs["subject"] == "Subject"
    assert kwargs["html_content"] == "<p>hi</p>"
    assert kwargs["sender"].email == "support@dorna.ai"


def test_send_failure_is_swallowed_and_logged(monkeypatch, caplog):
    fake_client = MagicMock()
    fake_client.transactional_emails.send_transac_email.side_effect = RuntimeError("boom")
    monkeypatch.setattr(be.brevo, "Brevo", MagicMock(return_value=fake_client))
    with caplog.at_level(logging.WARNING):
        be.send_signup_token_email("u@x.com", "tok")  # must not raise
    assert any("brevo_send_failed" in r.message for r in caplog.records)
